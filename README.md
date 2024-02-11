# MyTherapyPal

This is the main repository for the final MyTherapyPal application. It consists of a flutter mobile & web user interface application with account registration & login functionality, chat functionality and an AI mental health assistant chatbot, which is implemented using a REST API web service powered by Python Flask.

# Run debug environment

## AI(LLM) Mental Health Assistant API

The AI mental health assistant is using a 4-bit quantized Llama-2-13B model called TheBloke/Llama-2-13B-chat-GPTQ. The functionality of which is provided over flask API locally. This was developed using an NVidia 4060Ti 16GB graphics card with CUDA 12.3. There is a conda environment yaml file included to setup the environment. Below are the steps to set this up.

### Create the new conda enviroment (assuming you have anaconda3 or equivelant installed)
```bash
conda env create -f chatcbt_final.yml
conda activate chatCBTQ
```

### Start the flask server
```bash
cd chatCBT
python app.py
```

## Flutter Application

### Start the flutter application
```bash
flutter run
```

### Choose platform
Choose either Chrome, Edge, Windows, Android (if connected to device or emulator) or iOS (if on a MacOS system with Xcode). Selecting Windows may require Visual Studio being installed.
