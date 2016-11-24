# perl 笔记

### perl 正则: ./learning/regex.org

### LWP表单问题
对于可选的上传文件项与使用浏览器时不一样。使用浏览器时的request可以看到 filename=""这样的内容，而使用脚本时没有此项内容。

是request 请求的问题 -- LWP/MRequest.pm

### android 字符串导出
将android项目中的strings.xml 导出为xls(翻译用)

./excel/android_i18n.pl

```
# LWP
perl -MCPAN -e 'install Bundle::LWP'
perl -MCPAN -e 'install HTML::Parser' -e 'install HTML::Formatter'
# excel
perl -MCPAN -e 'install Spreadsheet::ParseExcel'
perl -MCPAN -e 'install Spreadsheet::WriteExcel'
# XML
perl -MCPAN -e 'install XML::Simple'
perl -MCPAN -e 'install XML::LibXML'
```

### 将号码归属地信息导入libphonenumber的txt文件中