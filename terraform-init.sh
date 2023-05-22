#!/bin/bash

# Define an associative array of Terraform directory paths with aliases
declare -A terraform_dirs=(
  ["Configure NSX-T"]="./02_nsxt_configure"
  ["Configure AVI"]="./03_nsx_alb_integration"
)

# Define the prerequisite tools to check for and install if necessary
prerequisites=(
  "govc"
  "ytt"
  "jq"
  "terraform"
)

# Check if prerequisite packages are installed and install them with elevated privileges if necessary
for package in "${prerequisites[@]}"
do
  if ! command -v "$package" > /dev/null; then
    echo "$package is not installed. Installing..."

    if [[ "$package" == "terraform" ]]; then
      # Install Terraform with elevated privileges
      curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
      sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
      sudo apt-get update && sudo apt-get install terraform
    else
      # Install the package with elevated privileges
      sudo apt-get update && sudo apt-get install -y "$package"
    fi

    echo "$package has been installed."
  else
    echo "$package is already installed."
  fi
done

# Prompt user to select an action to perform
echo "Please select an action to perform:"
select action in "Apply" "Destroy"
do
  case $action in
    "Apply")
      # Prompt user to select a directory to apply changes
      echo "Please select a Terraform directory to apply changes:"
      select dir_alias in "${!terraform_dirs[@]}"
      do
        dir=${terraform_dirs[$dir_alias]}
            # Navigate to the selected Terraform directory
            cd "$dir"

            # Initialize the Terraform directory
            terraform init

            # Plan the Terraform changes
            terraform plan -out=tfplan

            # Apply the Terraform changes
            terraform apply tfplan
          

          # Exit the loop
          break 2
       
          echo "Invalid selection. Please try again."
        
      done

      exit 0
      ;;
    "Destroy")
      # Prompt user to select a directory to destroy resources
      echo "Please select a Terraform directory to destroy resources:"
      select dir_alias in "${!terraform_dirs[@]}"
      do
        dir=${terraform_dirs[$dir_alias]}
        if [[ -d "$dir" ]]; then
          if [[ $dir_alias == "Build Jumpbox" ]]; then
            echo "Cannot destroy resources for Build Jumpbox. Please select a different directory."
          else
            # Navigate to the selected Terraform directory
            cd "$dir"

            # Destroy the Terraform resources
            terraform destroy
          fi

          # Exit the loop
          break 2
        else
          echo "Invalid selection. Please try again."
        fi
      done
      ;;
    *)
      # Invalid selection
      echo "Invalid selection. Please try again."
      ;;
  esac
done

exit 0