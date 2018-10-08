#!/bin/bash

# first check if conda is installed
CONDA_BINARY=$(which conda)
if [ -x "$CONDA_BINARY" ] ; then
	echo "Installation script will use this conda binary ${CONDA_BINARY} for installation"
else
	echo "No conda found!! Please see the README.md file for installation prerequisites."
	exit 1
fi


# file which containt conda configuration
CONDA_FILE="conda.yaml"
# virtual environment name
ENV_NAME="airship_bare"

# default CPU-only no-pySpark versions of conda packages.
pytorch="pytorch-cpu"
# TODO: torchvision-cpu does not seem to exist in pytorch channel
torchvision="torchvision"
tensorflow="tensorflow"
pyspark="#"

# flags to detect if both CPU and GPU are specified
gpu_flag=false
pyspark_flag=false

while [ ! $# -eq 0 ]
do
	case "$1" in
		--help)
			echo "Please specify --gpu to install with GPU-support and"
			echo "--pyspark to install with pySpark support"
			exit
			;;
		--gpu)
			pytorch="pytorch"
			torchvision="torchvision"
			tensorflow="tensorflow-gpu"
			ENV_NAME="airship_gpu"
			gpu_flag=true
			;;
		--pyspark)
			pyspark=""
			ENV_NAME="airship_pyspark"
			pyspark_flag=true
			;;			
		*)
			echo $"Usage: $0 invalid argument $1 please run with --help for more information."
			exit 1
	esac
	shift
done

if [ "$pyspark_flag" = true ] && [ "$gpu_flag" = true ]; then
	ENV_NAME="airship_full"
fi

/bin/cat <<EOM >${CONDA_FILE}
# To create the conda environment:
# $ conda env create -n my_env_name -f conda.yml
#
# To update the conda environment:
# $ conda env update -n my_env_name -f conda.yaml
#
# To register the conda environment in Jupyter:
# $ python -m ipykernel install --user --name my_env_name --display-name "Python (my_env_name)"
#

channels:
- pytorch
- conda-forge
- defaults
dependencies:
- jupyter==1.0.0
- python==3.6
- numpy>=1.13.3
- dask>=0.17.1
${pyspark}- pyspark==2.2.0
- pymongo>=3.6.1
- ipykernel>=4.6.1
- ${tensorflow}==1.5.0
- ${pytorch}==0.4.0
- scikit-surprise>=1.0.6
- scikit-learn==0.19.1
- jupyter>=1.0.0
- fastparquet>=0.1.6
- pip:
  - pandas>=0.22.0
  - scipy>=1.0.0
  - azure-storage>=0.36.0
  - tffm==1.0.1
  - pytest==3.6.4
  - pytest-cov
  - pytest-datafiles>=1.0
  - ${torchvision}
  - pylint>=2.0.1
  - pytest-pylint==0.11.0
EOM

# get current directory and create conda env dir relative to it as a full path
# DIR="$( cd "$( dirname $CONDA_BINARY )" >/dev/null && pwd )"
# ENV_DIR=$(realpath "${DIR}/../..")
CONDA_ROOT=$(conda env list | grep "^root\|^base" | cut -d"*" -f2 | tr -d '[:space:]')
ENV_DIR=${CONDA_ROOT}/envs
[[ -e $ENV_DIR ]] || mkdir -p ${ENV_DIR}

# get conda location for printing purposes only
CONDA_LOC=$(which conda)
# get actual env as a full absolute path
FULL_ENV_PATH=${ENV_DIR}/${ENV_NAME}

# generate conda environment
echo "Using Conda ${CONDA_LOC} to install environment name ${ENV_NAME} to ${ENV_DIR}"
conda env create --prefix ${FULL_ENV_PATH} -f ${CONDA_FILE}
echo "Temporarily activating ${ENV_NAME} to install Airship"
source activate ${ENV_DIR}/${ENV_NAME}
echo "Installing Airship..."
python setup.py install
echo "Done."
echo "Please run 'source activate $FULL_ENV_PATH' to use Airship in the new environment."

