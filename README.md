# terraform-aws-lambda-eventbridge-ec2-scheduler

[![Built with Terraform](https://img.shields.io/badge/Built%20with-Terraform-blue.svg)](https://www.terraform.io/)
[![AWS Lambda](https://img.shields.io/badge/AWS-Lambda-orange.svg)](https://aws.amazon.com/lambda/)
[![AWS EventBridge](https://img.shields.io/badge/AWS-EventBridge-purple.svg)](https://aws.amazon.com/eventbridge/)
[![Python](https://img.shields.io/badge/Python-3.9-blue.svg)](https://www.python.org/downloads/release/python-390/)

---

![Image](https://github.com/user-attachments/assets/3b658395-9877-4d60-812a-10dcfe039e49)

### Verifying Schedules: EventBridge Rules
Now that Terraform has deployed our EventBridge rules, it’s essential to confirm their configuration directly in the AWS Management Console. This step verifies that our schedules are correctly set up and understand how their UTC-based cron expressions translate to our desired local times.


![Image](https://github.com/user-attachments/assets/a1a6d81b-ccbb-4505-97dd-73af9a907b25)

Verify the Start EC2 Schedule:

![Image](https://github.com/user-attachments/assets/b6bcf35e-6add-4b8a-a429-3f403ae92c1a)

![Image](https://github.com/user-attachments/assets/3b5dc460-381a-460c-9126-ee247ada3db5)

- Observe the schedule_expression: You will see cron(0 3 ? * MON-FRI *).
- Understand the Time Translation: This cron expression specifies 03:00 AM UTC. Given that Pakistan Standard Time (PKT) is UTC+5, this translates to 8:00 AM PKT (03:00 UTC + 5 hours = 08:00 PKT). This confirms our instance will be scheduled to start at the beginning of the workday, Monday through Friday.

Targets:
![Image](https://github.com/user-attachments/assets/2a46cea0-feca-4f48-80d0-bbf9ae6005de)


## Verify the Stop EC2 Schedule:



### Targets:



