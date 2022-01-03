# 作業記録

## やろうとしていること

* AWS EC2でJenkinsをたてる
* AWS ECSでJenkinsをたてる

## 参照したもの

https://www.jenkins.io/doc/tutorials/tutorial-for-installing-jenkins-on-AWS/#jenkins-on-aws
にそってやっていく

## AWS EC2でJenkinsをたてる

### やったこと


#### Create a key pair

* EC2コンソール > NETWORK & SECURITYのKey Pairsをひらく
* Key Pairsを作成
  * jenkins_key_pairという名前で。
* 権限設定

```bash
$ ls -l jenkins_key_pair.pem
-rwxrwxrwx 1 ksanchu ksanchu 1674 Jan  4 08:36 jenkins_key_pair.pem
ksanchu@DESKTOP-93BSLTI:/mnt/c/Users/ksanc/Documents/work/docker/try_jenkins
$ chmod 400 jenkins_key_pair.pem
ksanchu@DESKTOP-93BSLTI:/mnt/c/Users/ksanc/Documents/work/docker/try_jenkins
$ ls -l jenkins_key_pair.pem
-r-------- 1 ksanchu ksanchu 1674 Jan  4 08:36 jenkins_key_pair.pem
ksanchu@DESKTOP-93BSLTI:/mnt/c/Users/ksanc/Documents/work/docker/try_jenkins
$
```

#### Create a security group



## 参考にしたリンク

