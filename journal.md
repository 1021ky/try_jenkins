# 作業記録

## やろうとしていること

* AWS EC2でJenkinsをたてる
* AWS ECSでJenkinsをたてる

## 参照したもの

https://www.jenkins.io/doc/tutorials/tutorial-for-installing-jenkins-on-AWS/#jenkins-on-aws
にそってやっていく

## AWS EC2でJenkinsをたてる

### やったこと

us-west-1で

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

22と8080にはアクセスできるようにした
まずは自分のグローバルIPアドレスからのみで。

VPCは
DNS ホスト名とDNS 解決を有効にしておかないと、インターネット公開されないようなので修正。
ルーティング設定しなかったのでsshつながらなかった

#### Using SSH to connect to your instance

```bash
$ aws ec2 describe-instances  --instance-ids i-0a517bc24c549527d  --query "Reservations[*].Instances[*].{Instance:InstanceId,NetworkInterfaces:NetworkInterfaces[*].Association.PublicDnsName}" --output json
[
    [
        {
            "Instance": "i-0a517bc24c549527d",
            "NetworkInterfaces": [
                "ec2-13-57-225-229.us-west-1.compute.amazonaws.com"
            ]
        }
    ]
]
```

aws ec2コマンドで、ssh先を取得

```bash
ssh -i ./jenkins_key_pair.pem ec2-user@ec2-13-57-225-229.us-west-1.compute.amazonaws.com
```

#### Download and install Jenkins

```bash
[ec2-user@ip-10-0-0-147 ~]$ sudo yum update –y
Loaded plugins: extras_suggestions, langpacks, priorities,
              : update-motd
amzn2-core                              | 3.7 kB     00:00
No Match for argument: –y
No packages marked for update
[ec2-user@ip-10-0-0-147 ~]$
```

updateするものはなかったようだ。

> Add the Jenkins repo using the following command:

```bash
[ec2-user@ip-10-0-0-147 ~]$ sudo wget -O /etc/yum.repos.d/jenkins.repo \
>     https://pkg.jenkins.io/redhat-stable/jenkins.repo
--2022-01-10 02:47:33--  https://pkg.jenkins.io/redhat-stable/jenkins.repo
Resolving pkg.jenkins.io (pkg.jenkins.io)... 151.101.42.133, 2a04:4e42:a::645
Connecting to pkg.jenkins.io (pkg.jenkins.io)|151.101.42.133|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 85
Saving to: ‘/etc/yum.repos.d/jenkins.repo’

100%[=====================>] 85          --.-K/s   in 0s

2022-01-10 02:47:34 (3.84 MB/s) - ‘/etc/yum.repos.d/jenkins.repo’ saved [85/85]

[ec2-user@ip-10-0-0-147 ~]$
```

> Import a key file from Jenkins-CI to enable installation from the package

```bash
[ec2-user@ip-10-0-0-147 ~]$ sudo yum install jenkins java-1.8.0-openjdk-devel -y

...

---> Package mesa-libglapi.x86_64 0:18.3.4-5.amzn2.0.1 will be installed
--> Finished Dependency Resolution
Error: Package: jenkins-2.319.1-1.1.noarch (jenkins)
           Requires: daemonize
 You could try using --skip-broken to work around the problem
 You could try running: rpm -Va --nofiles --nodigest
[ec2-user@ip-10-0-0-147 ~]$
```

以下を参考にして、daemonizeをインストール

* https://stackoverflow.com/questions/68806741/how-to-fix-yum-update-of-jenkins
* https://issues.jenkins.io/browse/JENKINS-66361

```bash
sudo amazon-linux-extras install epel -y
sudo yum update -y
```

リトライ

```bash
[ec2-user@ip-10-0-0-147 ~]$ sudo yum install jenkins java-1.8.0-openjdk-devel -y
Loaded plugins: extras_suggestions, langpacks, priorities,
              : update-motd

...

  xorg-x11-fonts-Type1.noarch 0:7.5-9.amzn2

Complete!
[ec2-user@ip-10-0-0-147 ~]$

```

エラーなく終了！

> Install Jenkins:
> Start Jenkins as a service:
>

```bash
[ec2-user@ip-10-0-0-147 ~]$ sudo systemctl daemon-reload
[ec2-user@ip-10-0-0-147 ~]$ sudo systemctl start jenkins
```

> You can check the status of the Jenkins service using the command:

```bash
[ec2-user@ip-10-0-0-147 ~]$ sudo systemctl status jenkins
● jenkins.service - LSB: Jenkins Automation Server
   Loaded: loaded (/etc/rc.d/init.d/jenkins; bad; vendor preset: disabled)
   Active: active (running) since Mon 2022-01-10 23:37:09 UTC; 9s ago
     Docs: man:systemd-sysv-generator(8)
  Process: 5592 ExecStart=/etc/rc.d/init.d/jenkins start (code=exited, status=0/SUCCESS)
   CGroup: /system.slice/jenkins.service
           └─5596 /etc/alternatives/java -Djava.awt.headless...

Jan 10 23:37:09 ip-10-0-0-147.us-west-1.compute.internal systemd[1]: ...
Jan 10 23:37:09 ip-10-0-0-147.us-west-1.compute.internal jenkins[5592]: ...
Jan 10 23:37:09 ip-10-0-0-147.us-west-1.compute.internal systemd[1]: ...
Hint: Some lines were ellipsized, use -l to show in full.
[ec2-user@ip-10-0-0-147 ~]$
```

動いているようだ。

> Connect to http://<your_server_public_DNS>:8080 from your favorite browser.

ということで

http://ec2-13-57-225-229.us-west-1.compute.amazonaws.com:8080/login?from=%2F
にアクセスして、無事jenkinsの設定画面が表示された。

```bash
[ec2-user@ip-10-0-0-147 ~]$ sudo cat /var/lib/jenkins/secrets/initialAdminPassword
3************************
[ec2-user@ip-10-0-0-147 ~]$
```

以下2つのプラグインをインストール。
ドキュメントではEC2だけ書かれていたが、ECRも後で試したいので。

* Amazon Web Services SDK :: EC2
* Amazon Web Services SDK :: ECR

プラグインによってEC2インスタンスをjenkins agentとして使えるようになるらしい。

まちがえていた。

インストールすべきはこっち

* Amazon EC2

EC2インスタンスの認証情報をいれると、エージェントとして使えるようになった。

## terraform化する

やったことの理解を深めるのと、再現をできるようにしたいのでterraform化する。

鍵の設定をterraformでどうしたらいいかわからなかった。
手元にはpemファイルしかない。
調べると以下の方法で変換できる。

ssh-keygen -y -f /path_to_key_pair/my-key-pair.pem

https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#retrieving-the-public-key

ksanchu@DESKTOP-93BSLTI:/mnt/c/Users/ksanc/Documents/work/docker/try_jenkins/terraform
$ ssh-keygen -y -f ../jenkins_key_pair.pem > jenkins_key_pa
ir.pub
ksanchu@DESKTOP-93BSLTI:/mnt/c/Users/ksanc/Documents/work/docker/try_jenkins/terraform
$

ssh-keygen -y オプションは

	OpenSSH形式の秘密鍵ファイルを読み出し、OpenSSH形式の公開鍵を標準出力に出力する

なので、作れると。

以下のように定義。

```terraform
resource "aws_key_pair" "try-jenkins-dev-keypair" {
  key_name   = "try-jenkins-dev-keypair"
  public_key = file("./jenkins_key_pair.pub") # `ssh-keygen`コマンドで作成した公開鍵を指定
}
```

これをinstanceのリソースに紐付ける。

```terraform
resource "aws_instance" "try-jenkins-dev-ec2" {
  ami           = data.aws_ssm_parameter.amazon-linux2-latest-ami.value
  instance_type = "t2.micro"
  key_name      = aws_key_pair.try-jenkins-dev-keypair.id

  ...
}

```

立てたインスタンスにsshできるようになった


## 参考にしたリンク

https://dev.classmethod.jp/articles/sales-create-ec2/