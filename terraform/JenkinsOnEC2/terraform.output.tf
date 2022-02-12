# apply後にElastic IPのパブリックIPを出力する
output "public_ip" {
  value = aws_eip.try-jenkins-dev-eip.public_ip
}
output "public_dns" {
  value = aws_eip.try-jenkins-dev-eip.public_dns
}