# Mautic-S3-Importer

The **Mautic-S3-Importer** is a powerful tool designed to automate the process of importing files from AWS S3 into Mautic. This script handles everything from fetching files from a specified S3 bucket to moving them into the appropriate directory for processing by Mautic's command line tools.

## Features

- **Automatic File Syncing**: Automatically fetches new files from a designated S3 bucket.
- **Mautic Integration**: Seamlessly moves files into Mautic's import directory.
- **Logging**: Detailed logs of all operations with timestamps for easy troubleshooting.
- **Batch Processing**: Supports the processing of multiple files simultaneously.

## Prerequisites

Before you begin, ensure you have the following installed:

- AWS CLI with access configured to your S3 bucket (`aws configure`)
- `s3cmd` tool for interacting with S3 (Install using `apt-get install s3cmd` on Debian/Ubuntu

or `yum install s3cmd` on CentOS)

- PHP and necessary libraries for running Mautic
- Mautic installed on your server

## Installation

1. Clone this repository to your local machine or server where Mautic is installed:

   ```bash
   git clone https://github.com/micwonder/Mautic-S3-Importer.git
   ```

2. Enter the cloned directory:

   ```bash
   cd Mautic-S3-Importer
   ```

3. Modify the script to include your specific S3 bucket details and Mautic directory paths in the provided variables.

## Usage

To start the import process, run the script from the terminal:

```bash
./s3_importer.sh
```

This will execute the following operations:

- Log the start of operations
- Fetch and list all files from your specified S3 bucket
- Download the files to a temporary directory
- Move the files to Mautic's import directory
- Trigger Mautic's file import commands

Logs of all operations will be saved to `/root/SCRIPTS/logfile.txt`.

## Customization

You can customize the script by modifying the following variables at the top of the `s3_importer.sh` file:

- `log_file`: Path to save the log file
- `src_dir`: Temporary directory for downloaded files
- `target_dir`: Mautic's directory for imports

## Troubleshooting

If you encounter any issues:

- Check the logfile (`/root/SCRIPTS/logfile.txt`) for any error messages or warnings.
- Ensure all configuration settings are correct, including S3 bucket access rights and local directory permissions.
- Verify that all prerequisites are correctly installed.

## Contributing

Contributions to the **Mautic-S3-Importer** are welcome! Please fork the repository and submit a pull request with your enhancements. You can also open issues for bugs or feature requests.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE) file for details.

---

### Notes

- Replace `https://github.com/micwonder/Mautic-S3-Importer.git` with the actual URL of your GitHub repository.
- Customize the installation and usage instructions based on your exact script configurations and user environment.
- Ensure all paths and example commands are accurate to avoid user confusion.
