resource "aws_iam_role" "ec2_role" {
  name = "ec2_secure_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
resource "aws_iam_role_policy" "restrict_s3_list" {
  name = "restrict-s3-list-buckets"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyListAllBuckets"
        Effect = "Deny"
        Action = "s3:ListAllMyBuckets"
        Resource = "*"
      },
      {
        Sid    = "AllowOnlyProjectBuckets"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::secure-multicloud-khadija-2026",
          "arn:aws:s3:::secure-multicloud-khadija-2026/*",
          "arn:aws:s3:::secure-multicloud-secure-data-2026",
          "arn:aws:s3:::secure-multicloud-secure-data-2026/*"
        ]
      }
    ]
  })
}
