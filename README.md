# simple_python_parser_infra
Pet-project for Terraform and Python trainings.

## SSH Login Monitoring Setup

### What Was Created (`vm_monitoring.tf`)

#### 1. Azure Monitor Agent
- Installed on the VM to collect logs and send them to Azure Monitor

#### 2. Data Collection Rule (DCR)
- Collects authentication logs from `/var/log/auth.log` 
- Monitors `auth` and `authpriv` syslog facilities
- Sends all logs to your existing Log Analytics workspace

#### 3. Data Collection Endpoint
- Provides a secure ingestion endpoint for the logs

#### 4. Scheduled Query Alert Rule
- **Runs every**: 5 minutes
- **Checks for**: SSH login events (successful authentication)
- **Detects**: 
  - "Accepted publickey" (SSH key login)
  - "Accepted password" (password login)
  - "session opened" events
- **Action**: Sends email notification via your action group

### How It Works

```
VM SSH Login → syslog (auth.log) → Azure Monitor Agent → 
Data Collection Rule → Log Analytics Workspace → 
Alert Query (every 5 min) → Action Group → Email to you
```

### Query Used for Detection

```kusto
Syslog
| where Computer == "<your-vm-name>"
| where Facility == "auth" or Facility == "authpriv"
| where SyslogMessage contains "Accepted publickey" or SyslogMessage contains "Accepted password" or SyslogMessage contains "session opened"
| where SyslogMessage contains "ssh" or ProcessName == "sshd"
| project TimeGenerated, Computer, SyslogMessage, ProcessName, HostIP
```

### Deployment

```bash
cd simple_python_parser_infra
terraform plan
terraform apply
```

### After Deployment

#### Test SSH Login
```bash
ssh azureuser@<vm-public-ip>
```

#### View Logs in Azure Portal
Navigate to: **Log Analytics Workspace → Logs** and run:
```kusto
Syslog
| where Facility == "auth" or Facility == "authpriv"
| where TimeGenerated > ago(1h)
| order by TimeGenerated desc
```

#### Check Alerts
- Go to **Monitor → Alerts** in Azure Portal
- You should receive an email within 5 minutes of any SSH login

### What You'll Get in Email Alerts

- Alert name: "SSH Login Detected"
- Severity: 2 (Warning)
- Details: Computer name, timestamp, login event details
- Query results showing who logged in and when

### Important Notes

⏱️ **Alert Frequency**: Checks every 5 minutes  
📧 **Notification**: Sent to your configured email  
🔒 **Security**: Monitors all SSH authentication attempts  
💾 **Data Retention**: Logs stored in Log Analytics (default: 30 days)  

The system will now alert you every time someone successfully logs into your VM via SSH!
