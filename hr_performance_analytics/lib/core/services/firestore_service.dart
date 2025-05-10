import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Reference to user's summaries collection
  CollectionReference get _summariesCollection {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    return _firestore.collection('users').doc(userId).collection('summaries');
  }
  
  // Save summaries to Firestore
  Future<void> saveSummariesToFirestore(List<Map<String, dynamic>> summaries) async {
    try {
      // Get batch to perform multiple operations
      final batch = _firestore.batch();
      
      // Add timestamp and ID to each summary
      final timestamp = Timestamp.now();
      
      for (var summary in summaries) {
        // Add timestamp to track when it was synced
        summary['syncedAt'] = timestamp;
        
        // Create a unique ID if none exists
        final String documentId = summary['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
        
        // Set document with merge to avoid overwriting existing data
        final docRef = _summariesCollection.doc(documentId);
        batch.set(docRef, summary, SetOptions(merge: true));
      }
      
      // Commit the batch
      await batch.commit();
      debugPrint('Successfully saved ${summaries.length} summaries to Firestore');
    } catch (e) {
      debugPrint('Error saving summaries to Firestore: $e');
      rethrow;
    }
  }
  
  // Get summaries from Firestore
  Future<List<Map<String, dynamic>>> getSummariesFromFirestore() async {
    try {
      final querySnapshot = await _summariesCollection.get();
      
      return querySnapshot.docs
          .map((doc) => {
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              })
          .toList();
    } catch (e) {
      debugPrint('Error getting summaries from Firestore: $e');
      rethrow;
    }
  }
  
  // Delete a summary from Firestore
  Future<void> deleteSummary(String summaryId) async {
    try {
      await _summariesCollection.doc(summaryId).delete();
      debugPrint('Successfully deleted summary: $summaryId');
    } catch (e) {
      debugPrint('Error deleting summary: $e');
      rethrow;
    }
  }
}