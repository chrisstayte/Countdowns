import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/screens/editor/crop_screen.dart';
import 'package:countdowns/storage/photos.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

typedef PickedPhoto = ({String path, PhotoCrops crops});

/// Picks a photo from the library, copies it into the app, and opens the
/// crop screen.
Future<PickedPhoto?> pickAndCropPhoto(
  BuildContext context,
  Countdown draft,
) async {
  final XFile? file;
  try {
    file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 90,
    );
  } catch (error) {
    debugPrint('Photo picker failed: $error');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t open your photos.')),
      );
    }
    return null;
  }
  if (file == null || !PhotoStore.ready) return null;
  final path = await PhotoStore.instance.import(file.path);
  if (!context.mounted) return (path: path, crops: const PhotoCrops());
  final crops = await cropPhoto(
    context,
    draft.copyWith(photoPath: path, photoCrops: const PhotoCrops()),
  );
  return (path: path, crops: crops ?? const PhotoCrops());
}

/// Opens the crop screen for the draft's photo.
Future<PhotoCrops?> cropPhoto(BuildContext context, Countdown draft) async {
  final path = draft.photoPath;
  if (path == null || !PhotoStore.ready) return null;
  return Navigator.of(context).push<PhotoCrops>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => CropScreen(
        file: PhotoStore.instance.fileFor(path),
        initial: draft.photoCrops ?? const PhotoCrops(),
      ),
    ),
  );
}
