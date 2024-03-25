import 'dart:async';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_therapy_pal/main.dart';
import 'package:my_therapy_pal/screens/login_screen.dart';
import '../services/auth_service.dart';
import 'package:cloud_functions/cloud_functions.dart';


class RegisterAccount extends StatefulWidget {
  const RegisterAccount({super.key});

  @override
  State<RegisterAccount> createState() => _RegisterAccountState();
}

class _RegisterAccountState extends State<RegisterAccount> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  final TextEditingController _fnameController = TextEditingController();
  final TextEditingController _snameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final List<String> _selectedDisciplines = [];
  String ratesFrom = '0';
  String ratesTo = '0';
  List<String> rates = List.generate(21, (index) => (index * 10).toString());
  List<dynamic> _placeList = [];
  FirebaseFunctions functions = FirebaseFunctions.instance;
  bool _shouldFetchSuggestions = true;
  String _lastSelectedAddress = '';
  Timer? _debounce;
  bool _passwordVisible = false;
  bool _isTherapistListingEnabled = false;
  List<String> disciplines = [];
  double _longitude = 0.0;
  double _latitude = 0.0;
  bool _isLoading = false;

  BoxBorder closedBorder = Border.all(
    color: Colors.grey[700]!,
    width: 1, 
  );
  BoxBorder expandedBorder = Border.all(
    color: Colors.teal,
    width: 2, 
  );

  
  String dropdownvalue = ''; 
  var items = ['', 'Patient', 'Therapist'];

  @override
  void initState() {
    super.initState();
    _addressController.addListener(_onAddressChanged);
    _passwordVisible = false;
    fetchDisciplines().then((fetchedDisciplines) {
      setState(() {
        disciplines = fetchedDisciplines;
      });
    });
  }

  void _onAddressChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (_addressController.text == _lastSelectedAddress) {
        // Do not fetch suggestions if the input matches the last selected address
        return;
      }
      if (_addressController.text.isNotEmpty) {
        _shouldFetchSuggestions = true;
        getSuggestions(_addressController.text);
      } else {
        setState(() => _placeList = []);
      }
    });
  }

  // Method to fetch disciplines
  Future<List<String>> fetchDisciplines() async {
    List<String> disciplines = [];

    // Reference to the collection
    CollectionReference disciplinesCollection = FirebaseFirestore.instance.collection('disciplines');

    // Get the snapshot with ordering by 'name' field alphabetically
    QuerySnapshot snapshot = await disciplinesCollection.orderBy('name').get();

    // Iterate through the documents and add the name to the list
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String name = data['name']; 
      disciplines.add(name); 
    }

    return disciplines; 
  }
  
  void getSuggestions(String input) async {
    if (!_shouldFetchSuggestions || input.trim().isEmpty) {
      setState(() {
        _placeList = [];
      });
      return;
    }

    try {
      final result = await functions.httpsCallable('getAddressSuggestions').call({'input': input});
      final List<dynamic> predictions = result.data;
      setState(() {
        _placeList = predictions;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<Map<String, dynamic>?> getCoordinatesByAddress(String address) async {
    try {
      final functions = FirebaseFunctions.instance;
      final HttpsCallable callable = functions.httpsCallable('getCoordinatesByAddress');

      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'address': address,
      });

      if (result.data != null) {
        return {
          'latitude': result.data['latitude'],
          'longitude': result.data['longitude'],
        };
      } else {
        print('No coordinates found for the address.');
        return null;
      }
    } catch (e) {
      print('Error fetching coordinates: $e');
      return null;
    }
  }

  void showGeneratingKeysDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Generating encryption keys..."),
              ],
            ),
          ),
        );
      },
    );
  }
  

  @override
  Widget build(BuildContext context) {
    double maxWidth = MediaQuery.of(context).size.width > 414 ? 414 : MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.teal,
          systemNavigationBarColor: Colors.teal,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 0.0, right: 12.0),
              child: Image.asset(
                'assets/images/logo.png',
                height: 24,
              ),
            ),
            const Text(
              MainApp.title,
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
       child: Center(
        child: AutofillGroup(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth / 1.2),
            child: Form(
              key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Create Account',
                      style: TextStyle(color: Colors.black, fontSize: 30),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your details below to create a new account.',
                      style: TextStyle(color: Colors.black, fontSize: 15),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height / 30,
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.teal, width: 1.0),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      autofillHints: const [AutofillHints.email],
                    ),
                    const SizedBox(height: 30.0),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.teal, width: 1.0),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      autofillHints: const [AutofillHints.password],
                    ),
                    const SizedBox(height: 30.0),
                    TextFormField(
                      controller: _passwordConfirmController,
                      obscureText: !_passwordVisible,
                      decoration: InputDecoration(
                        hintText: 'Confirm Password',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.teal, width: 1.0),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    const Divider(
                      color: Colors.grey,
                      thickness: 1,
                      indent: 10,
                      endIndent: 10,
                    ),
                    const SizedBox(height: 30.0),
                    TextFormField(
                      controller: _fnameController,
                      decoration: InputDecoration(
                        hintText: 'First Name',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.teal, width: 1.0),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    TextFormField(
                      controller: _snameController,
                      decoration: InputDecoration(
                        hintText: 'Last Name',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.teal, width: 1.0),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    DropdownButtonFormField(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.teal),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      value: dropdownvalue.isNotEmpty ? dropdownvalue : null,
                      items: items.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          dropdownvalue = newValue!;
                        });
                      },
                      hint: const Text("Select User Type"),
                    ),
                    const SizedBox(height: 15.0),
                    
                    if (dropdownvalue == 'Therapist') ...[
                      const Divider(
                        color: Colors.grey,
                        thickness: 1,
                        indent: 10,
                        endIndent: 10,
                      ),
                      const SizedBox(height: 15.0),
                      TextField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          hintText: "Begin typing your business address...",
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.teal, width: 1.0),
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          focusColor: Colors.white,
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                      ),
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _placeList.length,
                        itemBuilder: (context, index) {
                          final item = _placeList[index];
                          return InkWell(
                            onTap: () {
                              final selectedDescription = item["description"];
                              _addressController.text = selectedDescription;
                              _lastSelectedAddress = selectedDescription;
                              getCoordinatesByAddress(selectedDescription).then((coords) {
                                if (coords != null) {
                                  _longitude = coords['longitude'];
                                  _latitude = coords['latitude'];
                                } else {
                                  print('Coordinates could not be fetched.');
                                }
                              });
                              _shouldFetchSuggestions = false;
                              setState(() => _placeList = []);
                            },
                            child: ListTile(
                              title: Text(item["description"]),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                      CustomDropdown<String>.multiSelectSearch(
                        hintText: 'Please select relevant disciplines.',
                        items: disciplines,
                        onListChanged: (value) {
                          _selectedDisciplines.clear();
                          _selectedDisciplines.addAll(value);
                        },
                        listValidator: (value) => value.isEmpty ? "Must not be empty" : null,
                        decoration: CustomDropdownDecoration(
                          closedFillColor: Colors.grey[50],
                          expandedBorder: expandedBorder,
                          closedBorder: closedBorder,
                          closedBorderRadius: BorderRadius.circular(5.0),
                          expandedBorderRadius: BorderRadius.circular(5.0),
                          hintStyle: TextStyle(color: Colors.grey[700], fontSize: 16.0, fontFamily: 'Roboto Thin', fontWeight: FontWeight.w100),
                          listItemDecoration: const ListItemDecoration(
                            selectedColor: Color.fromARGB(0, 255, 255, 255),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          hintText: 'Contact number (optional)',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.teal, width: 1.0),
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      const Text(
                        'Rates',
                        style: TextStyle(color: Colors.black, fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'From:',
                        style: TextStyle(color: Colors.black, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField(
                        decoration: InputDecoration(
                          hintText: 'From',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.teal, width: 1.0),
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                        value: ratesFrom,
                        items: rates.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text("€$value"),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            ratesFrom = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'To:',
                        style: TextStyle(color: Colors.black, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField(
                        decoration: InputDecoration(
                          hintText: 'To',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.teal, width: 1.0),
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                        value: ratesTo,
                        items: rates.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text("€$value"),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            ratesTo = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 30),
                      SwitchListTile(
                        title: const Text('Enable Therapist Listing'),
                        value: _isTherapistListingEnabled,
                        onChanged: (bool value) {
                          setState(() {
                            _isTherapistListingEnabled = value;
                          });
                        },
                        subtitle: const Text('Turn this on if you would like to enable therapist listing.'),
                      ),
                    ],
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50.0,
                      child: ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            _isLoading = true; 
                          });
                          if(_isLoading){
                            // Show the loading dialog
                            showGeneratingKeysDialog(context);
                          }
                          final message = await AuthService().registration(
                            email: _emailController.text,
                            password: _passwordController.text,
                            passwordConfirm: _passwordConfirmController.text,
                            fname: _fnameController.text,
                            sname: _snameController.text,
                            userType: dropdownvalue,
                            address: _addressController.text,
                            phone: _phoneController.text,
                            disciplines: _selectedDisciplines,
                            ratesFrom: ratesFrom,
                            ratesTo: ratesTo,
                            isTherapistListingEnabled: _isTherapistListingEnabled,
                            longitude: _longitude,
                            latitude: _latitude,
                          );
                          if (message!.contains('Success')) {
                            setState(() {
                              _isLoading = false; 
                            });
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const Login()),
                              (route) => false,
                            );
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                            ),
                          );
                        },
                        
                        style: ButtonStyle(
                          minimumSize: MaterialStateProperty.all<Size>(const Size(double.infinity, 36)),
                        ),
                        child: const Text(
                          'SIGN UP',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    if (_isLoading)
                      Container(
                        color: Colors.black.withOpacity(0.5), 
                        child: const Center(
                          child: CircularProgressIndicator(), 
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  

  @override
  void dispose() {
    _addressController.removeListener(_onAddressChanged);
    _debounce?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _fnameController.dispose();
    _snameController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
