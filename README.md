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


Verify the Stop EC2 Schedule:


Similarly, navigate back to the Rules list and click on the rule named stop-ec2-daily-schedule.

![Image](https://github.com/user-attachments/assets/2e4067cd-8fe1-4ff2-b6a1-d3072225c5f5)

![Image](https://github.com/user-attachments/assets/1bb638d0-1644-4d6d-9531-8e5315577bea)

- Observe the schedule_expression: You will see cron(0 12 ? * MON-FRI *).
- Understand the Time Translation: This cron expression specifies 12:00 PM UTC. Translating this to PKT (UTC+5), it becomes 5:00 PM PKT (12:00 UTC + 5 hours = 17:00 PKT). This ensures our instance is scheduled to stop at the end of the workday, Monday through Friday.


Targets:

![Image](https://github.com/user-attachments/assets/fdac68b8-b8ee-4753-a028-45719ecb1053)


---


### Verifying Deployment: Lambda Functions


With our EventBridge schedules confirmed, the next step is to ensure our Lambda functions, which execute the actual start and stop actions, have been correctly deployed by Terraform.

![Image](https://github.com/user-attachments/assets/c7c9122d-7366-4ea5-a93d-7758ac016a96)

StartEC2Daily
![Image](https://github.com/user-attachments/assets/5ae752f4-7e49-46d2-8e65-f6bfd016852a)
![Image](https://github.com/user-attachments/assets/c3b2c8bf-ff86-4be7-9831-77ee686e4f92)

StopEC2Daily
![Image](https://github.com/user-attachments/assets/eedee304-352d-430c-b930-01e2730fea1b)
![Image](https://github.com/user-attachments/assets/db28c25a-7515-4969-b86b-8d038ad7f378)

---

### Verifying Execution: Lambda Functions (CloudWatch Logs)
Beyond just observing the EC2 instance state, examining the CloudWatch logs provides crucial insight into the Lambda functions’ execution, confirming they ran successfully and identified the correct instances.

![Image](https://github.com/user-attachments/assets/a87dfd4d-e6a0-4f1b-bbc9-76801ee11499)
![Image](https://github.com/user-attachments/assets/63e4416f-c7c6-41d9-a133-87fd7a037ac3)
![Image](https://github.com/user-attachments/assets/1a2a3d0e-e940-4321-a0ed-37d1ce2435d3)

### Witnessing the Automation in Action (EC2 Instance State Changes)






