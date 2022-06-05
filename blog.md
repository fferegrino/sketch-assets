Sometimes I use Sketch to create graphics for the content I create, however, I had always found it difficult to keep track of all my work. Saving files here and there, versioning them with what I thought was a sensible name schemes, only to realise that following such schemes requires a lot of mental effort.

My dream was always to be able to store my Sketch files in a *Git* repo; for some reason I always thought this would be impossible, that Sketche's files were binaries impossible to properly version...

In the following post, I'll explain why I was wrong, and how is it that you can version your *Sketch* files as plain text documents.

So I start with a base document, nothing too complex as I don't want to overcomplicate things:

![Simple image](https://ik.imagekit.io/thatcsharpguy/posts/sketch-in-git/Screenshot_2022-06-04_at_19.59.35.png?ik-sdk-version=javascript-1.4.3&updatedAt=1654369932542)

I have named this document *tcsg.sketch*; then, the next thing to understand is how Sketch actually saves these documents as a single file, the most important thing is that a *.sketch* file [is nothing more than a *.zip*](https://developer.sketch.com/file-format/?_ga=2.160187325.1466637750.1654335985-1710079208.1653454852) file with a bunch of *.json* files inside.

## De*sketchify*

We know that *Git* does not play nice with binary files but plays very nicely with plain text files – and *JSON* is just that. Why not we decompress the *.sketch* file and keep track of tje *.json* files alone; after all, when we want to open our file in Sketch again, we can simply compress those files again.

### Decompress

Witht this in mind, we can use:

```shell
unzip -d tcsg tcsg.sketch
```

To unzip the files into the `tcsg` repository. A quick glance into the newly unzipped repository gives us the following repo structure:

```text
tcsg
├── document.json
├── meta.json
├── pages
│   └── 4FB4BFA1-4E01-4EE8-9962-F07A85622B2F.json
├── previews
│   └── preview.png
└── user.json
```

I will not discuss the details of the files, as they are well explained Sketch's documentation.

A thing we should notice is that for optimisation purposes, the *JSON* files are saved with no indentation, all the contents are stored in a single line. As I want to embrace the full power of Git, I need to format these files to be able to view the diffs.

### Indent files

There is a useful tool to work with *JSON* fines from the *CLI*, it is named *jq*, I will use it to format the files with indentation:

```shell
find ./tcsg -type f -name "*.json" -exec sh -c "jq . {} | sponge {}"  \;
```

An explanation of the above command:

 - `find ./tcsg`: Searches for objects in the `./tcsg` folder
 - `-type f`: Specifies, with `f` that we are looking for a regular file
 - `-name "*.json"`: Filters the files we will find to all those ending in `.json`
 - `-exec [command]`: Executes a command for each file, within this command we can use `{}` to refer to the file name. The command to execute should be followed by `\;`
 - `sh -c "jq . {} | sponge {}"`: In this case, the command that will be executed for each file is `jq . [filename] | sponge [filename]`.

### Delete previews (optional)

There is a `previews` folder where the last page edited by the user is preserved to be used as a tumbnail (and a preview) for the document. Again, this is an image and for the time being, I will delete it since it is not needed for the file format.

```shell
rm -rf ./tcsg/previews/preview.png
```

And that is it! we now have a Sketch document as a series of plain text files.

## *Sketchify*

Of course, I want this process to be reversible – I want to be able to open my documents in Sketch again.

### Create a temporary folder

I rather not modify the original directory, so I will create a copy of the working directory:

```shell
cp -r ./tcsg ./tcsg_temp
```

### *Un*-indent files

When I decompressed the files, I realised that the *JSON* files contained all the information in a single line; to respect that format let's apply the `jq -c . {} | sponge {}` command to all those files. It is pretty similar to the format command above, with the difference of the `-c` flat of *jq*, which "compresses" the output.

```shell
find ./tcsg_temp -type f -name "*.json" -exec sh -c "jq -c . {} | sponge {}"  \;
```

### Remove previews (optional)

Again, let's delete any preview image, for consistency with the process above:

```shell
rm -rf ./tcsg_temp/previews/preview.png
```

### Putting everything together

I placed all the above code into a single file called `desketchify.sh`:

```shell
#!/usr/bin/env bash

unzip -o -d tcsg tcsg.sketch

find ./tcsg -type f -name "*.json" -exec  sh -c "jq . {} | sponge {}" \;

rm -rf ./tcsg/previews/preview.png
```

### Compress

Finally, the compression step, first we need to change directory to the temporary folder I have been working on. Then apply the compression step using the `zip` utility:

```shell
cd ./tcsg_temp; zip -r -X ../tcsg.sketch *
```

The flag `-r` specifies that `zip` should recursively compress the files; the `-X` flag specifies that the compression should not save any extra file attributes.

At the end of this command I should have a `.sketch` file that can be opened in the app.

### Cleanup

Lastly, let's clean up what I just did:

```shell
cd ..; rm -rf ./tcsg_temp
```

### Putting everything together

I placed all the above code into a single file called `sketchify.sh`:

```shell
#!/usr/bin/env bash

cp -r ./tcsg ./tcsg_temp

find ./tcsg_temp -type f -name "*.json" -exec  sh -c "jq -c . {} | sponge {}" \;

rm -rf ./tcsg_temp/previews/preview.png

cd ./tcsg_temp; zip -r -X ../tcsg.sketch *

cd ..; rm -rf ./tcsg_temp
```

## Generate a file using GitHub action

Of course, this process leaves a pretty much useless document for those that do not have the necessary tools to rebuild the sketch file from source. We can solve this problem with GitHub Actions, where we can build a *.sketch* file.

```yaml
name: Sketchify

on:
  workflow_dispatch:
  push:
    branches: [ "main" ]

jobs:
  compress:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install dependencies
        run: sudo apt-get install -y zip jq moreutils
      - name: Compress sketch
        run: ./sketchify.sh
      - uses: actions/upload-artifact@v3
        with:
          name: sketch-file
          path: tcsg.sketch
```

This will rebuild my sketch file every time new changes are made to the repository. The best part? the artifact will be available for download in the github UI:

![Artifact available to download](https://ik.imagekit.io/thatcsharpguy/posts/sketch-in-git/Screenshot_2022-06-05_at_07.12.06.png?ik-sdk-version=javascript-1.4.3&updatedAt=1654409559139)

## Conclusion

I consider this to be a pretty decent way to store Sketch files as assets in a Git repository, of course, depending on the changes you make, the diffs may still be mounstrous; but at least they are more trackable than as s single *zip* file.

To use the code described in this post you will need to make some adjustments to it to refere to your own files.

There is still a lot of things that I would like to do using Sketch documents, such as automatically export the artboards or desketchify the files as they are modified, instead of having to run the commands manually.
