# Push files to a server using sftp (and ssh)

In order to automate my Jekyll workflow, I thought about writing a bash script first. But why not use Ruby instead?

__Inspiration__ was found __[here](https://www.infoq.com/articles/ruby-file-upload-ssh-intro), where Matthew Bass__ ([Matthew's GitHub](https://github.com/pelargir)) wrote a nice little article dated 2007. Though its simplicity made it easy to grasp, the script had some flaws. If you used an FTP client for your first upload, and the directories of your project would change or would never be deeper than one level - you are good to go. Yet my project had nested directories and thanks to progress, the gems wouldn't work quite the same as in the old days of 2007.


# How to use?

Simply load the __script__ and the __config.yml__ to the root of your application.

Setup your Configuration in `config.yml`

``` yaml
host_url: 'yourdomain.com'
username: 'xyz'
local_path: './_site'
remote_path: '/httpdocs/public_html'
file_perm: 0o644
dir_perm: 0o755
```


The following commands are implemented:

* `$ ruby Upload2SFTP.rb upload [--config ./path-to-config.yml]`

    uploads new files and directories

* `$ ruby Upload2SFTP.rb clean [--config ./path-to-config.yml]`

    deletes all files and subdirectories

* `$ ruby Upload2SFTP.rb reupload [--config ./path-to-config.yml]`

    deletes all files and subdirectories and resyncs

* `$ ruby Upload2SFTP.rb remove [--config ./path-to-config.yml]`

    deletes all files, subdirectories and root

___

relies on the following gems, so either run `$ bundle` or:

``` bash
# https://github.com/net-ssh
$ gem install net-ssh
$ gem install net-sftp
$ gem install commander
```

### Pull requests are welcome! :octocat:
