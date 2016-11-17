## 准备
现有的86zh.txt 86en.txt

## 生成要用到的地址列表
``` add_list.pl *.xls ```
生成all_addrs.yaml 不合理的地址需要在中手动修改，查找 '=' '~'

## 导出单个xls文件
``` phone2txt.pl file_name.xls number_prefix ```
生成number_prefix_en.txt number_prefix_zh.txt
从number_prefix_en.txt number_prefix_zh.txt 中读取现有数据,并直接修改此文件
当number_prefix_en.txt 或number_prefix_zh.txt不存在时读取86zh.txt 86en.txt
