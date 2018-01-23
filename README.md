# Push files to a server using sftp (and ssh)

In order to automate my Jekyll workflow, I thought about writing a bash script first. But why not use Ruby instead?

__Inspiration__ was found [here](https://www.infoq.com/articles/ruby-file-upload-ssh-intro), where Matthew Bass ([Matthew's GitHub](https://github.com/pelargir)) wrote a nice little article dated 2007. Though its simplicity made it easy to grasp, the script had some flaws. If you used an FTP client for your first upload, and the directories of your project would change or would never be deeper than one level - you are good to go. Yet my project had nested directories and thanks to progress, the gems wouldn't work quite the same as in the old days of 2007.

Setup your Configuration in `config.yml`
___
``` yaml
host_url: 'yourdomain.com'
username: 'xyz'
local_path: './_site'
remote_path: '/httpdocs/public_html'
file_perm: 0o644
dir_perm: 0o755
```
___



relies on the following gems, so run `$ bundle` or:

``` bash
# https://github.com/net-ssh
$ gem install net-ssh
$ gem install net-sftp
```

### Pull requests are welcome! :octocat:
