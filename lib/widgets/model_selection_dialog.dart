import 'package:flutter/material.dart';
import 'package:chatgpt_clone/utils/app_colors.dart';

class ModelInfo {
  final String id;
  final String name;
  final String description;
  final String type;

  ModelInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
    );
  }
}

class ModelSelectionDialog extends StatefulWidget {
  final List<ModelInfo> models;
  final String currentModel;
  final Function(String) onModelSelected;

  const ModelSelectionDialog({
    Key? key,
    required this.models,
    required this.currentModel,
    required this.onModelSelected,
  }) : super(key: key);

  @override
  State<ModelSelectionDialog> createState() => _ModelSelectionDialogState();
}

class _ModelSelectionDialogState extends State<ModelSelectionDialog> {
  String? selectedModel;

  @override
  void initState() {
    super.initState();
    selectedModel = widget.currentModel;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.scaffoldBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.smart_toy, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Select ChatGPT Model',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Model List
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.models.length,
                itemBuilder: (context, index) {
                  final model = widget.models[index];
                  final isSelected = selectedModel == model.id;
                  
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected 
                        ? Border.all(color: Colors.blue, width: 2)
                        : Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                    ),
                    child: RadioListTile<String>(
                      value: model.id,
                      groupValue: selectedModel,
                      onChanged: (value) {
                        setState(() {
                          selectedModel = value;
                        });
                      },
                      activeColor: Colors.blue,
                      title: Text(
                        model.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text(
                            model.description,
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getTypeColor(model.type).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getTypeLabel(model.type),
                              style: TextStyle(
                                color: _getTypeColor(model.type),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Buttons
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selectedModel != null
                        ? () {
                            widget.onModelSelected(selectedModel!);
                            Navigator.of(context).pop();
                          }
                        : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Select Model',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'vision':
        return Colors.purple;
      case 'gpt-4':
        return Colors.blue;
      case 'gpt-3.5':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'vision':
        return 'Vision';
      case 'gpt-4':
        return 'GPT-4';
      case 'gpt-3.5':
        return 'GPT-3.5';
      default:
        return 'Other';
    }
  }
} 