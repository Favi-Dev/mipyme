import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/pyme_service.dart';

class PymeProvider extends ChangeNotifier {
  final PymeService _pymeService;
  
  List<UserProfile> _allPublicProfiles = [];
  List<Map<String, dynamic>> _specialOffers = [];
  
  bool _isLoadingProfiles = true;
  bool _isLoadingOffers = true;

  StreamSubscription? _pymesSubscription;
  StreamSubscription? _foundationsSubscription;
  StreamSubscription? _offersSubscription;

  PymeProvider(this._pymeService) {
    _initStreams();
  }

  void _initStreams() {
    _pymesSubscription = _pymeService.getPymes().listen((profiles) {
      // Retain existing foundations, replace pymes
      _allPublicProfiles.removeWhere((p) => p.role == UserRole.pyme);
      _allPublicProfiles.addAll(profiles);
      _isLoadingProfiles = false;
      notifyListeners();
    }, onError: (error) {
      if (kDebugMode) print('Error fetching pymes: $error');
      _isLoadingProfiles = false;
      notifyListeners();
    });

    _foundationsSubscription = _pymeService.getFoundations().listen((profiles) {
      // Retain existing pymes, replace foundations
      _allPublicProfiles.removeWhere((p) => p.role == UserRole.foundation);
      _allPublicProfiles.addAll(profiles);
      _isLoadingProfiles = false;
      notifyListeners();
    }, onError: (error) {
      if (kDebugMode) print('Error fetching foundations: $error');
      _isLoadingProfiles = false;
      notifyListeners();
    });

    _offersSubscription = _pymeService.getSpecialOffersGlobal().listen((offers) {
      _specialOffers = offers;
      _isLoadingOffers = false;
      notifyListeners();
    }, onError: (error) {
      if (kDebugMode) print('Error fetching offers: $error');
      _isLoadingOffers = false;
      notifyListeners();
    });
  }

  List<UserProfile> get pymes => 
      _allPublicProfiles.where((p) => p.role == UserRole.pyme).toList();
      
  List<UserProfile> get foundations => 
      _allPublicProfiles.where((p) => p.role == UserRole.foundation).toList();
      
  List<UserProfile> get allPublicProfiles => _allPublicProfiles;
      
  List<Map<String, dynamic>> get specialOffers => _specialOffers;

  bool get isLoadingProfiles => _isLoadingProfiles;
  bool get isLoadingOffers => _isLoadingOffers;
  bool get isLoading => _isLoadingProfiles || _isLoadingOffers;

  @override
  void dispose() {
    _pymesSubscription?.cancel();
    _foundationsSubscription?.cancel();
    _offersSubscription?.cancel();
    super.dispose();
  }
}
