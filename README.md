In order to automate my Jekyll workflow, I thought about writing a bash script first. But why not use Ruby instead?

__Inspiration__ was found [here](https://www.infoq.com/articles/ruby-file-upload-ssh-intro), where Matthew Bass ([Matthew's GitHub](https://github.com/pelargir)) wrote a nice little article dated 2007. Though its simplicity made it easy to grasp, the script had some flaws. If you used an FTP client for your first upload, and the directories of your project would change or would never be deeper than one level - you are good to go. Yet my project had nested directories and thanks to progress, the gems wouldn't work quite the same as in the old days of 2007.

___
__Attention:__ my script isn't perfect yet, because it is fine for me as it is.

One thing, that would enhance it quite a bit, would be parsing a config file, instead of setting the variable in the method itself.
___

Pull requests are welcome! :octocat:

relies on the following gems:

``` bash
# https://github.com/net-ssh
$ gem install net-ssh
$ gem install net-sftp
```
