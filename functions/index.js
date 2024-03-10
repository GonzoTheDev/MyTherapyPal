/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const functions = require('firebase-functions');
const googleMapsClient = require('@google/maps').createClient({
    key: 'AIzaSyBXlQ9lhzngAHiyW9tSwMmoJX9M6xigzBI',
    Promise: Promise
});

exports.getAddressSuggestions = functions.https.onCall(async (data, context) => {
    const input = data.input;
    if (!input) {
        throw new functions.https.HttpsError('invalid-argument', 'You must provide an address input.');
    }

    try {
        const response = await googleMapsClient.placesAutoComplete({
            input: input,
            language: 'en',
            components: {country: 'IE'}
        }).asPromise();

        return response.json.predictions;
    } catch (error) {
        throw new functions.https.HttpsError('unknown', 'Failed to fetch address suggestions.', error);
    }
});

exports.getCoordinatesByAddress = functions.https.onCall(async (data, context) => {
    const address = data.address;
    if (!address) {
        throw new functions.https.HttpsError('invalid-argument', 'You must provide an address.');
    }

    try {
        const response = await googleMapsClient.geocode({
            address: address,
            components: {country: 'IE'}
        }).asPromise();

        if (response.json.results.length > 0) {
            const location = response.json.results[0].geometry.location;
            return {
                latitude: location.lat,
                longitude: location.lng
            };
        } else {
            throw new functions.https.HttpsError('not-found', 'No location found for the specified address.');
        }
    } catch (error) {
        console.error('Geocode error:', error);
        throw new functions.https.HttpsError('unknown', 'Failed to fetch the coordinates.', error);
    }
});
