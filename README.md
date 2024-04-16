# MyTherapyPal

This is the main repository for the final MyTherapyPal application. It consists of a flutter desktop, mobile & web user interface application with account registration & login functionality, chat functionality and an AI mental health assistant chatbot, which is implemented using a REST API web service powered by Python Flask.

# Application Screenshots

![alt text](https://github.com/GonzoTheDev/MyTherapyPal/blob/main/assets/images/screenshots1.png?raw=true)

![alt text](https://github.com/GonzoTheDev/MyTherapyPal/blob/main/assets/images/screenshots2.png?raw=true)

![alt text](https://github.com/GonzoTheDev/MyTherapyPal/blob/main/assets/images/screenshots3.png?raw=true)


# Run debug environment

## AI(LLM) Mental Health Assistant API

The AI mental health assistant is using a 4-bit quantized Llama-2-13B model called TheBloke/Llama-2-13B-chat-GPTQ. The functionality of which is provided over flask API locally. This was developed using an NVidia 4060Ti 16GB graphics card with CUDA 12.3. There is a conda environment yaml file included to setup the environment. Below are the steps to set this up.

### Create the new conda enviroment (assuming you have anaconda3 or equivelant installed)
```bash
conda env create -f chatCBTQ.yml
conda activate chatCBTQ
```

### Start the flask server
```bash
cd chatCBT
python app.py
```

### Start the reverse proxy (needs ngrok installed & ngrok account with static endpoint url)
```bash
ngrok http http://localhost:5000
```

## Flutter Application

### Start the flutter application
```bash
flutter run
```

### Choose platform
Choose either Chrome, Edge, Windows, Android (if connected to device or emulator), iOS or macOS. Selecting Windows may require Visual Studio being installed.
