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
