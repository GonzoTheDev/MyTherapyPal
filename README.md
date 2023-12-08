# my_therapy_pal

This is the main repository for the MyTherapyPal proof-of-concept prototype application. It consists of a flutter mobile & web user interface application with account registration & login functionality along with a note taking system connected to a primitive AI emotional sentiment analysis API, and the API itself, which is a REST API web service powered by Python Flask.

# Run debug environment

## Emotional Sentiment Analysis API

### Create the new conda enviroment (assuming you have anaconda3 or equivelant installed)
```bash
conda env create -f environment.yml
conda activate emotion_sentiment
```

### Start the flask server
```bash
cd emotional_sentiment_analysis
python app.py
```

## Flutter Application

### Start the flutter application
```bash
flutter run
```

### Choose platform
Choose either Chrome or Edge. Selecting Windows may require Visual Studio being installed.