# perl 笔记

### perl 正则: ./learning/regex.org

### LWP表单问题
对于可选的上传文件项与使用浏览器时行为不一样。使用浏览器时的request可以看到 filename=""这样的内容，而使用脚本时没有此项内容。

由 HTTP::Request::Common 修改 -- LWP/MRequest.pm
