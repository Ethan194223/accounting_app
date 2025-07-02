// lib/ar_view_page.dart (Attempting to Load Local 3d_ar_pet.glb)
// IMPORTANT: This code assumes the underlying AR plugin is correctly initialized
// AND that it provides valid hitTestResults.
// The current issue with ar_flutter_plugin_2 v0.0.3 is that it's failing on these.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for PlatformException
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/datatypes/hittest_result_types.dart';
import 'package:vector_math/vector_math_64.dart';

class ARViewPage extends StatefulWidget {
  const ARViewPage({super.key});

  @override
  State<ARViewPage> createState() => _ARViewPageState();
}

class _ARViewPageState extends State<ARViewPage> {
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;
  late ARAnchorManager arAnchorManager;
  bool arManagersInitialized = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Pet View (Local Pet)'),
      ),
      body: ARView(
        onARViewCreated: onARViewCreated,
      ),
    );
  }

  Future<void> onARViewCreated(
      ARSessionManager sessionManager,
      ARObjectManager objectManager,
      ARAnchorManager anchorManager,
      ARLocationManager locationManager,
      ) async {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;

    print("ARView created. Initializing AR managers...");

    try {
      await arSessionManager.onInitialize(
        showFeaturePoints: false,
        showPlanes: true,
        showWorldOrigin: false,
        handleTaps: true,
      );
      print("ARSessionManager initialized successfully.");

      arSessionManager.onPlaneOrPointTap = _onPlaneOrPointTap;
      print("onPlaneOrPointTap callback assigned.");

      await arObjectManager.onInitialize(); // This is where the MissingPluginException occurred with v0.0.3
      print("ARObjectManager initialized successfully.");
      arManagersInitialized = true;

    } on PlatformException catch (e) {
      print("PLATFORM EXCEPTION during AR manager initialization: ${e.message}");
      print("Error code: ${e.code}");
      print("Error details: ${e.details}");
      arManagersInitialized = false;
    } catch (e) {
      print("GENERAL EXCEPTION during AR manager initialization: $e");
      arManagersInitialized = false;
    }

    if (arManagersInitialized) {
      print("All AR managers initialized. Tap a detected plane to place your Pet model.");
    } else {
      print("AR managers FAILED to initialize. Tap functionality and object placement will likely be affected or non-functional.");
    }
  }

  Future<void> _onPlaneOrPointTap(List<ARHitTestResult> hitTestResults) async {
    print("--- _onPlaneOrPointTap FUNCTION ENTERED (Local Pet Test) ---");
    print("Received hitTestResults list with length: ${hitTestResults.length}");

    if (!arManagersInitialized) {
      print("_onPlaneOrPointTap: AR Managers were not initialized successfully. Cannot add node.");
      return;
    }

    if (hitTestResults.isEmpty) {
      print("Local Pet Test: No hit test results found on tap (hitTestResults list is empty).");
      print("--- _onPlaneOrPointTap FUNCTION EXITED (due to empty hitTestResults) ---");
      return;
    }

    // Log details of each hit result
    for (int i = 0; i < hitTestResults.length; i++) {
      var hit = hitTestResults[i];
      print("Hit result $i: type=${hit.type}, distance=${hit.distance}, worldTransform=${hit.worldTransform.getTranslation()}");
    }

    ARHitTestResult firstHit = hitTestResults.first;
    print("Using first hit result: type=${firstHit.type}");

    print("Local Pet Test: Tap registered. Using first hit. Attempting to add 3d_ar_pet.glb node...");

    final Matrix4 worldTransform = firstHit.worldTransform;
    final Vector3 position = Vector3(
        worldTransform.getTranslation().x,
        worldTransform.getTranslation().y,
        worldTransform.getTranslation().z
    );

    var newNode = ARNode(
      type: NodeType.webGLB, // For ar_flutter_plugin_2 v0.0.3, webGLB is used for local assets too
      uri: "assets/images/3d_Ar_pet.glb", // Path to your local pet model
      scale: Vector3(0.2, 0.2, 0.2), // STARTING SCALE - ADJUST THIS IF MODEL IS INVISIBLE/TOO BIG/SMALL
      position: position,
      rotation: Vector4(0.0, 0.0, 0.0, 1.0), // Identity rotation
    );

    try {
      bool? nodeAdded = await arObjectManager.addNode(newNode);
      if (nodeAdded == true) {
        print("Local Pet Test SUCCESS: Node added successfully at $position using URI: ${newNode.uri}");
      } else {
        print("Local Pet Test FAILURE: Failed to add Pet node (nodeAdded was false or null). URI: ${newNode.uri}");
      }
    } on PlatformException catch (e) {
      print("PLATFORM EXCEPTION while adding Pet node: ${e.message}. Code: ${e.code}. Details: ${e.details}. URI: ${newNode.uri}");
    } catch (e) {
      print("GENERAL ERROR while adding Pet node: $e. URI: ${newNode.uri}");
    }
    print("--- _onPlaneOrPointTap FUNCTION EXITED (Local Pet Test) ---");
  }

  @override
  void dispose() {
    if (arManagersInitialized) { // Only dispose if initialized to avoid potential null errors if init failed
      arSessionManager.dispose();
      print("ARSessionManager disposed.");
    } else {
      print("ARSessionManager was not disposed as it might not have been fully initialized.");
    }
    super.dispose();
  }
}















