# syntax=docker/dockerfile:1
# For GPU support run the container with "docker run -it --gpus=all <image-name>" 
# If running on Linux, you may need to install the Nvidia Container Toolkit: 
# https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#docker 
# It is recommended to use an Azure Container for PyTorch (ACPT) base image. 
# See: https://learn.microsoft.com/en-us/azure/machine-learning/resource-azure-container-for-pytorch 
# To find available ACPT images, open https://ml.azure.com/registries/azureml/environments 
# and search for "ACPT". 
# New versions of the ACPT images are released often, so it is recommended to update the version number periodically 
#   (note the :number at the end of the image spec). 
FROM mcr.microsoft.com/azureml/curated/acpt-pytorch-2.2-cuda12.1:9 
SHELL ["/bin/bash", "-c"] 
ARG DEBIAN_FRONTEND=noninteractive 
# Ensure active user is root. 
USER root 
# Install system dependencies. 
RUN apt-get update && \
    apt-get install -y unzip git git-lfs curl sudo azcopy
# Install SHEPHERD environment. 
COPY environment.yml install_pyg.sh ./ 
RUN conda env create -y -f environment.yml && source activate shepherd && bash install_pyg.sh
RUN rm environment.yml install_pyg.sh 
# Set azcopy env variables
ENV AZCOPY_LOG_LOCATION=logs
ENV AZCOPY_JOB_PLAN_LOCATION=logs
