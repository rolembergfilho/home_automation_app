import 'package:flutter/material.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/user_data.dart';
import 'package:home_automation/utils/show_progress.dart';
import 'package:home_automation/utils/internet_access.dart';
import 'package:home_automation/utils/show_dialog.dart';
import 'package:home_automation/utils/show_internet_status.dart';
import 'package:home_automation/utils/check_platform.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class UserProfile extends StatefulWidget {
  final User user;
  final Function callbackUser;
  UserProfile({this.user, this.callbackUser});
  @override
  UserProfileState createState() {
    return UserProfileState(user, callbackUser);
  }
}

class UserProfileState extends State<UserProfile>
    implements UserUpdateContract {
  bool _isLoading = false;
  bool internetAccess = false;
  CheckPlatform _checkPlatform;

  User user;
  ShowDialog showDialog;
  ShowInternetStatus _showInternetStatus;
  UserUpdatePresenter _userUpdatePresenter;

  String _name, _email, _mobile, _address, _city;
  var scaffoldKey = new GlobalKey<ScaffoldState>();
  var formKey = new GlobalKey<FormState>();
  bool _autoValidate = false;

  final FocusNode _nameFocus = new FocusNode();
  final FocusNode _addressFocus = new FocusNode();
  final FocusNode _cityFocus = new FocusNode();
  final FocusNode _mobileFocus = new FocusNode();

  Function callbackUser;

  Function callbackThis(User userDetails) {
    this.callbackUser(userDetails);
    setState(() {
      this.user = userDetails;
    });
  }

  UserProfileState(User user, callbackUser) {
    this.user = user;
    this.callbackUser = callbackUser;
    setUserVariables();
  }

  @override
  initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    showDialog = new ShowDialog();
    _userUpdatePresenter = new UserUpdatePresenter(this);
    _checkPlatform = new CheckPlatform(context: context);
    _showInternetStatus = new ShowInternetStatus();
    getInternetAccessObject();
    super.initState();
  }

  @override
  void dispose() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    super.dispose();
  }

  Future getInternetAccessObject() async {
    CheckInternetAccess checkInternetAccess = new CheckInternetAccess();
    bool internetAccessDummy = await checkInternetAccess.check();
    setState(() {
      internetAccess = internetAccessDummy;
    });
  }

  setUserVariables() {
    try {
      _email = this.user.email;
      _name = this.user.name;
      _mobile = this.user.mobile;
      _address = this.user.address;
      _city = this.user.city;
    } catch (e) {
      Navigator.of(context).pop();
    }
  }

  void _showSnackBar(String text) {
    this
        .scaffoldKey
        .currentState
        .showSnackBar(new SnackBar(content: new Text(text)));
  }

  @override
  void onUserUpdateError(String errorString) {
    setState(() {
      _isLoading = false;
    });
    this.showDialog.showDialogCustom(context, "Error", errorString);
  }

  @override
  void onUserUpdateSuccess(User userDetails) {
    this.callbackThis(userDetails);
    setState(() {
      _isLoading = false;
    });
    this
        .showDialog
        .showDialogCustom(context, "Success", "Profile Details Updated");
  }

  void _fieldFocusChange(
      BuildContext context, FocusNode current, FocusNode next) {
    current.unfocus();
    FocusScope.of(context).requestFocus(next);
  }

  Future _updateUserProfile() async {
    await getInternetAccessObject();
    if (internetAccess) {
      var form = formKey.currentState;
      if (form.validate()) {
        form.save();
        if (this.user.name != _name ||
            this.user.city != _city ||
            this.user.mobile != _mobile ||
            this.user.address != _address) {
          setState(() {
            _isLoading = true;
          });
          await _userUpdatePresenter.doUpdateUser(
              _email, _name, _address, _city, _mobile);
        } else {
          this
              .showDialog
              .showDialogCustom(context, "Success", "Profile Details Updated");
        }
      } else {
        _autoValidate = true;
      }
    } else {
      this.showDialog.showDialogCustom(context, "Internet Connection Problem",
          "Please check your internet connection",
          fontSize: 17.0, boxHeight: 58.0);
    }
  }

  Widget _showBody(BuildContext context) {
    String cityValidator(String value) {
      Pattern pattern = r'^[a-zA-Z]+$';
      RegExp regex = new RegExp(pattern);
      if (value.isEmpty)
        return 'City should not be empty';
      else if (!regex.hasMatch(value))
        return 'City should not contain special characters';
      else if (value.length <= 2)
        return "City should have more than 2 characters";
      else
        return null;
    }

    String contactValidator(String value) {
      Pattern pattern = r'^[0-9]{10}$';
      RegExp regex = new RegExp(pattern);
      if (value.isEmpty)
        return 'Contact should not be empty';
      else if (!regex.hasMatch(value))
        return 'Contact should only 10 contain numbers';
      else
        return null;
    }

    String nameValidator(String value) {
      Pattern pattern = r'^[a-zA-Z0-9]+$';
      Pattern pattern2 = r'^([0-9])+[a-zA-Z0-9]+$';
      RegExp regex = new RegExp(pattern);
      RegExp regex2 = new RegExp(pattern2);
      if (value.isEmpty)
        return 'Name should not be empty';
      else if (!regex.hasMatch(value))
        return 'Name should not contain special character';
      else if (regex2.hasMatch(value))
        return 'Name should not start with alpanumerics';
      else if (value.length <= 3)
        return "Name should have more than 3 characters";
      else
        return null;
    }

    String addressValidator(String value) {
      Pattern pattern = r'^[0-9a-zA-Z,/. ]+$';
      RegExp regex = new RegExp(pattern);
      if (value.isEmpty)
        return 'Address should not be empty';
      else if (!regex.hasMatch(value))
        return 'Address should have only [,/. ] special characters';
      else if (value.length <= 8)
        return "Address should have more than 8 characters";
      else
        return null;
    }

    return Container(
      child: ListView(
        children: <Widget>[
          SizedBox(
            height: 10.0,
          ),
          Container(
            padding: EdgeInsets.all(20.0),
            child: Column(
              children: <Widget>[
                Card(
                  elevation: 10.0,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: kHAutoBlue300, width: 2.0),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(10.0),
                      child: Form(
                        key: formKey,
                        autovalidate: _autoValidate,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            FlatButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                _showSnackBar("Email can not be change!");
                              },
                              child: TextFormField(
                                initialValue: _email,
                                enabled: false,
                                decoration: InputDecoration(
                                  hintText: "Email",
                                  contentPadding: EdgeInsets.fromLTRB(
                                      20.0, 20.0, 20.0, 10.0),
                                  prefixIcon: Icon(
                                    Icons.email,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(32.0),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 21.0,
                            ),
                            TextFormField(
                              initialValue: _name,
                              onSaved: (val) {
                                _name = val;
                              },
                              autofocus: true,
                              focusNode: _nameFocus,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              onFieldSubmitted: (val) {
                                _fieldFocusChange(
                                    context, _nameFocus, _addressFocus);
                              },
                              decoration: InputDecoration(
                                hintText: "Name",
                                contentPadding:
                                    EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
                                prefixIcon: Icon(
                                  Icons.person,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(32.0),
                                ),
                              ),
                              validator: nameValidator,
                            ),
                            SizedBox(
                              height: 21.0,
                            ),
                            TextFormField(
                              initialValue: _address,
                              onSaved: (val) {
                                _address = val;
                              },
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.sentences,
                              focusNode: _addressFocus,
                              onFieldSubmitted: (val) {
                                _fieldFocusChange(
                                    context, _addressFocus, _cityFocus);
                              },
                              decoration: InputDecoration(
                                hintText: "Address",
                                contentPadding:
                                    EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
                                prefixIcon: Icon(
                                  Icons.home,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(32.0),
                                ),
                              ),
                              validator: addressValidator,
                            ),
                            SizedBox(
                              height: 21.0,
                            ),
                            TextFormField(
                              initialValue: _city,
                              onSaved: (val) {
                                _city = val;
                              },
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.next,
                              focusNode: _cityFocus,
                              onFieldSubmitted: (val) {
                                _fieldFocusChange(
                                    context, _cityFocus, _mobileFocus);
                              },
                              decoration: InputDecoration(
                                hintText: "City",
                                contentPadding:
                                    EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
                                prefixIcon: Icon(
                                  Icons.location_city,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(32.0),
                                ),
                              ),
                              validator: cityValidator,
                            ),
                            SizedBox(
                              height: 21.0,
                            ),
                            TextFormField(
                              initialValue: _mobile,
                              onSaved: (val) {
                                _mobile = val;
                              },
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              focusNode: _mobileFocus,
                              onFieldSubmitted: (val) async {
                                _mobileFocus.unfocus();
                                await _updateUserProfile();
                              },
                              decoration: InputDecoration(
                                hintText: "Mobile",
                                contentPadding:
                                    EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
                                prefixIcon: Icon(
                                  Icons.phone,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(32.0),
                                ),
                              ),
                              validator: contactValidator,
                            ),
                            SizedBox(
                              height: 21.0,
                            ),
                            RaisedButton(
                              color: kHAutoBlue300,
                              onPressed: () async {
                                await _updateUserProfile();
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                "Update",
                                style: TextStyle(
                                  fontSize: 15.0,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20.0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: _checkPlatform.isIOS()
          ? CupertinoNavigationBar(
              backgroundColor: kHAutoBlue100,
              middle: new Text("Edit Profile"),
            )
          : new AppBar(
              title: new Text("Edit Profile"),
            ),
      body: internetAccess
          ? _isLoading ? ShowProgress() : _showBody(context)
          : _checkPlatform.isIOS()
              ? new CustomScrollView(
                  slivers: <Widget>[
                    new CupertinoSliverRefreshControl(
                      onRefresh: getInternetAccessObject,
                    ),
                    new SliverSafeArea(
                        top: false,
                        sliver: _showInternetStatus
                            .showInternetStatus(_checkPlatform.isIOS())),
                  ],
                )
              : RefreshIndicator(
                  child: _showInternetStatus
                      .showInternetStatus(_checkPlatform.isIOS()),
                  onRefresh: getInternetAccessObject,
                ),
    );
  }
}
