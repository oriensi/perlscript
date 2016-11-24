## 准备
将resource/zh/86.txt 拷贝到本目录下并重命名为86zh.txt,resource/en/86.txt 拷贝到本目录下并重命名为86en.txt

## 生成要用到的地址列表
``` add_list.pl *.xls ```
生成all_addrs.yaml 不合理的地址需要在中手动修改，查找 '=' '~'

## 导出单个xls文件
如：将 173H.xls的号码导出
``` phone2txt.pl 173H.xls 173 > log.txt ```
将86zh.txt 86en.txt中173开头的号码与xls表中比较并生成 86173_en.txt 86173_zh.txt(当 86173_en.txt 或86173_zh.txt 存在时代替86zh(en).txt)
, 标准输出为更新的条目

将该号段的信息直接替换进去就行，看情况修改PhoneNumberMetadata.xml 文件

