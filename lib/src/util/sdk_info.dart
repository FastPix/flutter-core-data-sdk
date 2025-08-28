
class SdkInfo {
  static SdkInformationModel getPackageInformation() {
    final sdkInformation = SdkInformationModel("flutter_core_sdk", "1.0.0");
    return sdkInformation;
  }
}

class SdkInformationModel {
  final String sdkName;
  final String sdkVersion;

  const SdkInformationModel(this.sdkName, this.sdkVersion);
}
