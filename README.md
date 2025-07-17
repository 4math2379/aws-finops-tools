# AWS FinOps Tools

[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)](https://docs.docker.com/compose/)
[![AWS](https://img.shields.io/badge/AWS-Cost%20Management-FF9900?logo=amazon-aws)](https://aws.amazon.com/aws-cost-management/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://makeapullrequest.com)
[![Version](https://img.shields.io/badge/version-v1.0.0-blue)](https://github.com/4math2379/aws-finops-tools/releases/tag/v1.0.0)

A comprehensive Docker-based solution that enables FinOps teams, SysOps, and financial analysts to manage AWS costs, optimize spending, and predict future expenses across multiple AWS accounts and landing zones.

## Overview

This repository provides a containerized approach to AWS cost management, financial operations (FinOps), and cost optimization across multiple AWS accounts. Originally developed for managing costs across multiple AWS landing zones, this tool empowers FinOps teams to leverage AWS native cost management services for comprehensive financial governance.

### Target Audience

- **FinOps Teams**: Streamline cost management and optimization across multiple AWS accounts
- **Financial Analysts**: Conduct comprehensive cost analysis and forecasting
- **SysOps Teams**: Monitor and optimize infrastructure costs in multi-account environments
- **Cloud Financial Managers**: Maintain cost governance across complex AWS organizations
- **Landing Zone Administrators**: Manage costs across multiple customer environments

### Key Use Cases

- **Multi-Account Cost Analysis**: Analyze costs and usage across numerous AWS accounts
- **Cost Optimization**: Identify and implement cost-saving opportunities
- **Budget Management**: Create and monitor budgets across accounts and services
- **Cost Forecasting**: Predict future AWS spending using historical data
- **Reserved Instance Management**: Optimize RI utilization and purchasing decisions
- **Automated Reporting**: Generate financial reports for stakeholder review

## Features

- **Multi-Account Support**: Manage costs for multiple AWS accounts simultaneously
- **Containerized Environment**: Isolated Docker containers for each account
- **Automated Scripts**: Collection of bash scripts for common FinOps operations
- **Cost Analysis**: Deep dive into costs by service, region, and usage type
- **Budget Monitoring**: Track budget performance and alerts
- **RI Optimization**: Reserved Instance utilization and recommendations
- **Cost Forecasting**: Predictive analytics for future spending
- **CSV Export**: Generate cost reports in CSV format for further analysis
- **Web Dashboard**: Interactive visualization of cost data and trends
- **REST API**: Programmatic access to all cost data and reports
- **Real-time Updates**: Automatic data refresh and live metrics

## Supported AWS Services & Tools

### Cost Management Services
- AWS Cost Explorer
- AWS Budgets
- AWS Cost and Usage Reports (CUR)
- AWS Billing Console
- AWS Cost Anomaly Detection

### Optimization Services
- AWS Compute Optimizer
- AWS Trusted Advisor
- AWS Well-Architected Cost Optimization
- AWS Savings Plans
- Reserved Instances

### Analytics & Reporting
- AWS Cost Intelligence Dashboard
- AWS CloudWatch (Cost metrics)
- AWS QuickSight (Cost visualization)
- AWS Cost Categories
- AWS Resource Groups

## Prerequisites

- Docker and Docker Compose installed
- AWS credentials configured for each account
- AWS Cost Explorer API access
- AWS Budgets permissions in target accounts
- AWS Cost and Usage Reports (CUR) enabled (recommended)

## Project Structure

```
aws-finops-tools/
├── docker-compose.yml          # Docker composition for multi-account setup
├── aws-credentials/           # AWS credentials for each account
│   ├── account1/
│   ├── account2/
│   ├── account3/
│   └── master/
├── aws-scripts/              # FinOps automation scripts
│   ├── get-cost-usage.sh
│   ├── get-budget-status.sh
│   ├── analyze-cost-trends.sh
│   ├── get-ri-utilization.sh
│   ├── get-savings-plans.sh
│   ├── cost-optimization.sh
│   ├── export-cost-csv.sh
│   ├── forecast-costs.sh
│   └── aggregate-costs.sh
├── output/                   # Output directory for reports
│   ├── account1/
│   ├── account2/
│   ├── account3/
│   └── aggregated/
└── docker/                   # Docker-related files

```

## Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/4math2379/aws-finops-tools.git
   cd aws-finops-tools
   ```

2. **Configure AWS credentials**
   
   Place your AWS credentials in the appropriate directories:
   ```bash
   # For each account, create credentials and config files
   mkdir -p aws-credentials/account1
   # Add credentials and config files with Cost Explorer permissions
   ```

3. **Create output directories**
   ```bash
   mkdir -p output/{account1,account2,account3,aggregated}
   ```

4. **Start the containers**
   ```bash
   docker-compose up -d
   ```

## Usage

### Access a specific account container
```bash
# For account 1
docker-compose exec awscli-account1 bash

# For account 2
docker-compose exec awscli-account2 bash

# For the aggregator (master account)
docker-compose exec finops-aggregator bash
```

### Run FinOps scripts

Inside any container, you can run the following scripts:

1. **Get Cost and Usage Data**
   ```bash
   ./get-cost-usage.sh
   ```

2. **Check Budget Status**
   ```bash
   ./get-budget-status.sh
   ```

3. **Analyze Cost Trends**
   ```bash
   ./analyze-cost-trends.sh
   ```

4. **Get Reserved Instance Utilization**
   ```bash
   ./get-ri-utilization.sh
   ```

5. **Get Savings Plans Information**
   ```bash
   ./get-savings-plans.sh
   ```

6. **Cost Optimization Analysis**
   ```bash
   ./cost-optimization.sh
   ```

7. **Export Costs to CSV**
   ```bash
   ./export-cost-csv.sh
   ```

8. **Forecast Future Costs**
   ```bash
   ./forecast-costs.sh
   ```

9. **Aggregate Costs Across Accounts**
   ```bash
   ./aggregate-costs.sh
   ```

10. **Run Demo (All Scripts)**
    ```bash
    ./run-demo.sh
    ```

## Data Visualization

### Web Dashboard
Access the interactive web dashboard at `http://localhost:8080` after starting the services.

**Features:**
- **Real-time Metrics**: Total costs, forecasted costs, RI utilization, Savings Plans utilization
- **Interactive Charts**: Daily cost trends, cost distribution by service and region
- **Account Status**: Live status of all account containers and data freshness
- **File Browser**: Direct access to all generated JSON reports
- **Auto-refresh**: Updates every 5 minutes automatically

### REST API
Access the REST API at `http://localhost:8081` for programmatic data access.

**Key Endpoints:**
- `GET /api/health` - API health check
- `GET /api/latest-data` - Latest cost data for dashboard
- `GET /api/accounts` - List all available accounts
- `GET /api/files` - List all data files
- `GET /api/cost-summary` - Cost summary across accounts
- `GET /api/metrics` - Key metrics for dashboard
- `GET /api/file/{account}/{filename}` - Download specific file

### Starting the Visualization Services

```bash
# Start all services including dashboard and API
docker-compose up -d

# Access the web dashboard
open http://localhost:8080

# Check API health
curl http://localhost:8081/api/health

# Generate sample data
docker-compose exec awscli-account1 bash
./run-demo.sh
```

## Real-World Benefits

### From Field Experience

This tool has proven invaluable for FinOps teams managing costs across multiple environments:

- **Multi-Landing Zone Cost Management**: Efficiently track and optimize costs across different customer environments
- **Standardized Cost Analysis**: Apply consistent FinOps practices across diverse AWS architectures
- **Time Efficiency**: Reduce cost analysis time from days to hours with automated reporting
- **Comprehensive Insights**: Generate executive-ready cost reports across all accounts
- **Proactive Cost Management**: Identify cost anomalies and optimization opportunities early

### Why FinOps Teams Choose This Tool

1. **Isolation**: Each AWS account runs in its own container, preventing credential conflicts
2. **Repeatability**: Standardized scripts ensure consistent cost analysis across engagements
3. **Scalability**: Easily add new accounts or cost centers as needed
4. **Auditability**: All cost reports and analyses are timestamped and preserved
5. **FinOps Best Practices**: Apply proven financial operations practices across organizations

## Configuration

### Region Configuration
The default region is set to `us-east-1` (required for Cost Explorer API). To change it, modify the `AWS_DEFAULT_REGION` environment variable in `docker-compose.yml`.

### Adding New Accounts
To add a new account, add a new service in `docker-compose.yml`:
```yaml
awscli-account4:
  image: amazon/aws-cli:latest
  container_name: aws-finops-account4
  volumes:
    - ./aws-credentials/account4:/root/.aws:ro
    - ./aws-scripts:/aws-scripts:ro
    - ./output/account4:/output
  working_dir: /aws-scripts
  environment:
    - AWS_DEFAULT_REGION=us-east-1
    - ACCOUNT_NAME=account4
  entrypoint: ["/bin/bash"]
  tty: true
  stdin_open: true
  networks:
    - aws-finops-network
```

## Security Considerations

- AWS credentials are mounted as read-only volumes
- Each account runs in an isolated container
- Scripts directory is mounted as read-only
- Output directories are account-specific
- Cost data is sensitive and should be handled securely

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues, questions, or contributions, please open an issue in the GitHub repository.
