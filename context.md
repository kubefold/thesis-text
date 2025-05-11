Tworzę projekt o nazwie KubeFold. KubeFold to projekt operatora Kubernetes, który ma za zadanie automatyzować proces uruchamiania algorytmu AlphaFold na klastrach Kubernetes.
Tworzę pracę magisterską na uczelni AGH w Krakowie na temat tego projektu.

# Operator

# 🧬 Kubefold

Kubefold is a Kubernetes operator for managing protein structure prediction workflows. It provides a declarative way to handle protein databases and run conformation predictions in a Kubernetes cluster.

## 🚀 Features

- **Protein Database Management** - Download and manage various protein databases (UniProt, PDB, BFD, etc.)
- **Conformation Prediction** - Run protein structure predictions with configurable parameters
- **Cloud Integration** - Store results in S3 and receive notifications via SMS
- **Scalable Architecture** - Built on Kubernetes for horizontal scaling and resource management

## 📋 Prerequisites

- Kubernetes cluster (v1.11.3+)
- kubectl (v1.11.3+)
- Access to an S3 bucket for storing results
- AWS credentials for S3 and SMS notifications (if using these features)

## 🛠️ Installation

```sh
kubectl apply -f https://raw.githubusercontent.com/kubefold/operator/main/dist/install.yaml
```

## 📝 Usage

### Protein Database

Create a ProteinDatabase resource to download and manage protein databases:

```yaml
apiVersion: data.kubefold.io/v1
kind: ProteinDatabase
metadata:
  name: my-database
spec:
  datasets:
    uniprot: true
    pdb: true
  volume:
    storageClassName: fsx-sc
```

### Protein Conformation Prediction

Run a protein structure prediction:

```yaml
apiVersion: data.kubefold.io/v1
kind: ProteinConformationPrediction
metadata:
  name: my-prediction
spec:
  database: my-database
  protein:
    id: ['A']
    sequence: "YOUR_PROTEIN_SEQUENCE"
  model:
    volume:
      storageClassName: fsx-sc
    weights:
      http: "https://your-model-weights.bin.zst"
  destination:
    s3:
      bucket: your-bucket
      region: your-region
  notify:
    region: your-region
    sms:
      - "+1234567890"
```

## 🧹 Cleanup

To uninstall the operator:

```sh
kubectl delete -f https://raw.githubusercontent.com/kubefold/operator/main/dist/install.yaml
```

## ☁️ Running on AWS EKS

This project provides resources for easy deployment on Amazon EKS, including GPU and FSx Lustre support for high-performance workloads.

- `eks/cluster.yaml`: Example EKS cluster configuration (with CPU and GPU node groups, IAM policies, and VPC setup) for use with `eksctl`.
- `eks/fsx.storageclass.k8s.yaml`: StorageClass for FSx for Lustre, enabling fast, shared storage for protein data and models.
- `eks/sample-lustre-volume.k8s.yaml`: Sample PersistentVolumeClaim using the FSx StorageClass.
- `up.sh`: Automated script to provision the EKS cluster, install the FSx CSI driver, set up storage, deploy Kubefold, and apply a sample resource. Run this script for a one-command setup (requires AWS CLI, eksctl, and kubectl configured).

**Note:**
- The provided EKS configuration includes a GPU node group using `g5.xlarge` instances. You must request a quota increase for g5 instances in your AWS region before running the setup.

**Quick start:**
(Recommended) Run the automated setup script:
```sh
# Automatically:
# - creates EKS cluster with GPU nodegroup
# - installs AWS FSx CSI Driver for automated FSx for Lustre volume provisioning
# - create fsx-sc storage class
# - installs kubefold controller
# - deploys sample ProteinDatabase
./up.sh
```

These resources help you get started with scalable, cloud-native protein prediction workflows on AWS.

# Downloader
# 🧬 Protein Database Downloader

A tool for downloading and decompressing protein databases for bioinformatics research.

## About

Protein Database Downloader is a utility designed to fetch large protein datasets from AlphaFold's database. It supports rate limiting, progress tracking, and automatic decompression of downloaded files.

Developed by Mateusz Woźniak <matisiek11@gmail.com>

## Supported Datasets

The following protein datasets are supported:

- `mgy_clusters_2022_05.fa` - MGY Clusters
- `bfd-first_non_consensus_sequences.fasta` - BFD non-consensus sequences
- `uniref90_2022_05.fa` - UniRef90
- `uniprot_all_2021_04.fa` - UniProt
- `pdb_2022_09_28_mmcif_files.tar` - PDB mmCIF files
- `pdb_seqres_2022_09_28.fasta` - PDB sequence resources
- `rnacentral_active_seq_id_90_cov_80_linclust.fasta` - RNACentral
- `nt_rna_2023_02_23_clust_seq_id_90_cov_80_rep_seq.fasta` - NT RNA
- `rfam_14_9_clust_seq_id_90_cov_80_rep_seq.fasta` - RFam

## Usage

### Environment Variables

The application is configured using the following environment variables:

- `DATASET` (required): The dataset to download (must be one of the supported datasets listed above)
- `DESTINATION` (required): The directory path where the downloaded dataset will be saved
- `RATE` (optional): Download rate limit in KB/s (default: unlimited)

### Docker

```bash
docker run -e DATASET=rfam_14_9_clust_seq_id_90_cov_80_rep_seq.fasta \
           -e DESTINATION=/data \
           -e RATE=1024 \
           -v /local/path:/data \
           kubefold/downloader
```

### Building from Source

```bash
git clone https://github.com/kubefold/downloader.git
cd downloader
go build -o downloader ./cmd/main.go
```

### Running the Binary

```bash
DATASET=rfam_14_9_clust_seq_id_90_cov_80_rep_seq.fasta \
DESTINATION=/data \
RATE=1024 \
./downloader
```

## Features

- Downloads datasets from AlphaFold's database
- Automatically decompresses zstd-compressed files
- Configurable download rate limiting
- Progress tracking with size information
- SHA-256 hash verification for downloaded files

# Manager
# 🧬 Kubefold Manager

A utility service for managing protein folding tasks with AWS infrastructure support.

## About

Kubefold Manager is a versatile utility designed to handle various aspects of protein folding workflows. It provides functionality for:

1. Handling and validating input data
2. Uploading prediction artifacts to S3
3. Sending SMS notifications about task completion

Developed as part of the Kubefold project ecosystem for protein structure prediction.

## Usage

### Environment Variables

The application is configured using the following environment variables:

#### Required for all operations:
* `INPUT_PATH`: Directory path where input files are located
* `OUTPUT_PATH`: Directory path where output files are generated

#### For input processing:
* `ENCODED_INPUT`: Base64-encoded JSON input data for folding tasks

#### For artifact uploading:
* `BUCKET`: S3 bucket name where artifacts will be uploaded

#### For notifications:
* `NOTIFICATION_PHONES`: Comma-separated list of phone numbers to notify
* `NOTIFICATION_MESSAGE`: Custom message to send in the notification

### Docker

```bash
docker run -e INPUT_PATH=/data/input \
           -e OUTPUT_PATH=/data/output \
           -e BUCKET=my-result-bucket \
           -v /local/input:/data/input \
           -v /local/output:/data/output \
           kubefold/manager
```

### AWS Credentials

For S3 uploads and SNS notifications, the application uses the AWS SDK's default credential provider chain. Ensure appropriate AWS credentials are available through:

- Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
- AWS credentials file
- IAM roles for Amazon EC2 or ECS tasks

## Features

* Process and validate protein folding input data
* Upload prediction results to Amazon S3
* Send SMS notifications via Amazon SNS
* Containerized for easy deployment in cloud environments

## Building from Source

```bash
git clone https://github.com/kubefold/manager.git
cd manager
go build -o manager ./cmd/main.go
```

## Related Projects

* [kubefold/downloader](https://github.com/kubefold/downloader): Utility for downloading protein databases 