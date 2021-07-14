import Foundation
import Capacitor
import AVFoundation

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */

@objc(Mixer)
public class Mixer: CAPPlugin {
    
    private var audioFileList: [String : AudioFile] = [:]
    private var micInputList: [String : MicInput] = [:]
    public var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    public var engine: AVAudioEngine = AVAudioEngine()
    public var isAudioSessionActive: Bool = false
    public var audioFileInterruptionList: [String] = []
    public var audioSessionListenerName: String = ""
    public let nc: NotificationCenter = NotificationCenter.default
    
    public override func load() {
        super.load()
    }
    
    // MARK: initAudioSession
    @objc func initAudioSession(_ call: CAPPluginCall) {
        initAudioProxy(call)
//        if (isAudioSessionActive == true) {
//            call.resolve(buildBaseResponse(wasSuccessful: false, message: "Audio Session is already active, please call 'deinitAudioSession' prior to initializing a new audio session."))
//            return
//        }
//
//        audioSessionListenerName = call.getString("audioSessionListenerName") ?? ""
//        let inputPortType = call.getString("inputPortType") ?? ""
////        let outputPortType = call.getString("outputPortType") ?? ""
//        let ioBufferDuration = call.getDouble("ioBufferDuration") ?? -1
//
//        do {
////            try audioSession.setActive(false)
//            try audioSession.setCategory(.multiRoute , mode: .default, options: [.defaultToSpeaker])
//            if (ioBufferDuration > 0) {
//                try audioSession.setPreferredIOBufferDuration(ioBufferDuration)
//            }
////            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
//        }
//        catch let error {
//            isAudioSessionActive = false
//            call.resolve(buildBaseResponse(wasSuccessful: false, message: "There was a problem initializing your audio session with exception: \(error)"))
//            return
//        }
//        if let inputDesc = audioSession.availableInputs?.first(where: {(desc) -> Bool in
//            print("Available Input: ", desc)
//            return determineAudioSessionPortDescription(desc: desc, type: inputPortType)
//        }) {
//            do {
////                try audioSession.setActive(false)
//                try audioSession.setPreferredInput(inputDesc)
////                try audioSession.setActive(true)
//            } catch let error {
//                isAudioSessionActive = false
//                call.resolve(buildBaseResponse(wasSuccessful: false, message: "There was a problem initializing your audio session with exception: \(error)"))
//                print(error)
//                return
//            }
//        }
//        do {
//            try audioSession.setActive(true)
//            print("Current route is: \(audioSession.currentRoute)")
//            registerForSessionInterrupts()
//            registerForSessionRouteChange()
//        } catch let error {
//            isAudioSessionActive = false
//            call.resolve(buildBaseResponse(wasSuccessful: false, message: "There was a problem initializing your audio session with exception: \(error)"))
//            print(error)
//            return
//        }
//
//        let response = ["preferredInputPortType": audioSession.preferredInput?.portType as Any,
//                        "preferredInputPortName": audioSession.preferredInput?.portName as Any,
//                        "preferredIOBufferDuration": Float(audioSession.preferredIOBufferDuration)] as [String : Any]
//        print("preferredIOBufferDuration: ", audioSession.preferredIOBufferDuration)
//        isAudioSessionActive = true
//
//        call.success(buildBaseResponse(wasSuccessful: true, message: "successfully initialized audio session", data: response))
    }
    
    // MARK: initAudioProxy
    private func initAudioProxy(_ call: CAPPluginCall) {
        if (isAudioSessionActive == true) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "Audio Session is already active, please call 'deinitAudioSession' prior to initializing a new audio session."))
            return
        }
        
        audioSessionListenerName = call.getString("audioSessionListenerName") ?? ""
        let inputPortType = call.getString("inputPortType") ?? ""
//        let outputPortType = call.getString("outputPortType") ?? ""
        let ioBufferDuration = call.getDouble("ioBufferDuration") ?? -1
        
        do {
//            try audioSession.setActive(false)
            try audioSession.setCategory(.multiRoute , mode: .default, options: [.defaultToSpeaker])
            if (ioBufferDuration > 0) {
                try audioSession.setPreferredIOBufferDuration(ioBufferDuration)
            }
//            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        }
        catch let error {
            isAudioSessionActive = false
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "There was a problem initializing your audio session with exception: \(error)"))
            return
        }
        if let inputDesc = audioSession.availableInputs?.first(where: {(desc) -> Bool in
            print("Available Input: ", desc)
            return determineAudioSessionPortDescription(desc: desc, type: inputPortType)
        }) {
            do {
//                try audioSession.setActive(false)
                try audioSession.setPreferredInput(inputDesc)
//                try audioSession.setActive(true)
            } catch let error {
                isAudioSessionActive = false
                call.resolve(buildBaseResponse(wasSuccessful: false, message: "There was a problem initializing your audio session with exception: \(error)"))
                print(error)
                return
            }
        }
        do {
//            try audioSession.setActive(true)
            print("Current route is: \(audioSession.currentRoute)")
            registerForSessionInterrupts()
            registerForSessionRouteChange()
            registerForMediaServicesWereReset()
            registerForMediaServicesWereLost()
        } catch let error {
            isAudioSessionActive = false
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "There was a problem initializing your audio session with exception: \(error)"))
            print(error)
            return
        }
        
        let response = ["preferredInputPortType": audioSession.preferredInput?.portType as Any,
                        "preferredInputPortName": audioSession.preferredInput?.portName as Any,
                        "preferredIOBufferDuration": Float(audioSession.preferredIOBufferDuration)] as [String : Any]
        print("preferredIOBufferDuration: ", audioSession.preferredIOBufferDuration)
        isAudioSessionActive = true

        call.success(buildBaseResponse(wasSuccessful: true, message: "successfully initialized audio session", data: response))
    }
    
    // MARK: deinitAudioSession
    @objc func deinitAudioSession(_ call: CAPPluginCall) {
        do {
            try audioSession.setActive(false)
            isAudioSessionActive = false
            call.success(buildBaseResponse(wasSuccessful: true, message: "Successfully deinitialized audio session"))
        } catch let error {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "ERROR deinitializing audio session with exception: \(error)"))
            return
        }
    }
    
    // MARK: resetPlugin
    @objc func restartPlugin(_ call: CAPPluginCall) {
        do {
            try audioSession.setActive(false)
            isAudioSessionActive = false
        } catch let error {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "ERROR deinitializing audio session with exception: \(error)"))
            return
        }
        audioFileList.forEach { (key: String, value: AudioFile) in
            _ = value.destroy()
        }
        micInputList.forEach { (key: String, value: MicInput) in
            _ = value.destroy()
        }
        audioFileList = [:]
        micInputList = [:]
        engine = AVAudioEngine()
        audioSession = AVAudioSession.sharedInstance()
    }
    
    // MARK: getAudioSessionPreferredInputPortType
    @objc func getAudioSessionPreferredInputPortType(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        call.success(buildBaseResponse(wasSuccessful: true, message: "got preferred input", data: ["value": audioSession.preferredInput!.portType]))
    }

    // MARK: initMicInput
    @objc func initMicInput(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        let audioId = call.getString("audioId") ?? ""
        let channelNumber = call.getInt("channelNumber") ?? -1
        if (channelNumber == -1) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "from initMicInput - no channel number"))
            return
        }
        if (micInputList[audioId] != nil) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "from initMicInput - audioId already in use"))
            return
        }
        let eqSettings: EqSettings = EqSettings()
        let channelSettings: ChannelSettings = ChannelSettings()
        
        eqSettings.bassGain = call.getFloat("bassGain") ?? 0.0
        eqSettings.bassFrequency = call.getFloat("bassFrequency") ?? 115.0
        eqSettings.midGain = call.getFloat("midGain") ?? 0.0
        eqSettings.midFrequency = call.getFloat("midFrequency") ?? 500.0
        eqSettings.trebleGain = call.getFloat("trebleGain") ?? 0.0
        eqSettings.trebleFrequency = call.getFloat("trebleFrequency") ?? 1500.0
        
        channelSettings.volume = call.getFloat("volume") ?? 1.0
        channelSettings.channelListenerName = call.getString("channelListenerName") ?? ""
        channelSettings.eqSettings = eqSettings
        channelSettings.channelNumber = channelNumber
        
        micInputList[audioId] = MicInput(parent: self, audioId: audioId)
        
        micInputList[audioId]?.setupAudio(audioFilePath: NSURL(fileURLWithPath: ""), channelSettings: channelSettings)
        call.success(buildBaseResponse(wasSuccessful: true, message: "mic was successfully initialized"))
    }
    
    // MARK: destroyMicInput
    @objc func destroyMicInput(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        guard let audioId = getAudioId(call: call, functionName: "isPlaying") else {return}
        let response = micInputList[audioId]!.destroy()
        micInputList[audioId] = nil
        call.success(buildBaseResponse(wasSuccessful: true, message: "Mic input \(audioId) destroyed", data: response))
    }
    
    // MARK: initAudioFile
    @objc func initAudioFile(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        let filePath = call.getString("filePath") ?? ""
        let audioId = call.getString("audioId") ?? ""
        let eqSettings: EqSettings = EqSettings()
        let channelSettings: ChannelSettings = ChannelSettings()
        
        eqSettings.bassGain = call.getFloat("bassGain") ?? 0.0
        eqSettings.bassFrequency = call.getFloat("bassFrequency") ?? 115.0
        eqSettings.midGain = call.getFloat("midGain") ?? 0.0
        eqSettings.midFrequency = call.getFloat("midFrequency") ?? 500.0
        eqSettings.trebleGain = call.getFloat("trebleGain") ?? 0.0
        eqSettings.trebleFrequency = call.getFloat("trebleFrequency") ?? 1500.0
        
        channelSettings.volume = call.getFloat("volume") ?? 1.0
        channelSettings.channelListenerName = call.getString("channelListenerName") ?? ""
        channelSettings.eqSettings = eqSettings
        
        if (filePath.isEmpty) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "from initAudioFile - filePath not found"))
            return
        }
        if (audioId.isEmpty) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "from initAudioFile - audioId not found"))
            return
        }
        if (audioFileList[audioId] != nil) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "from initAudioFile - audioId already in use"))
            return
        }
        // TODO: implement check for overwriting existing audioID
        audioFileList[audioId] = AudioFile(parent: self, audioId: audioId)
        if (filePath != "") {
            let scrubbedString = filePath.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? ""
            let urlString = NSURL(string: scrubbedString)
            if (urlString != nil) {
                audioFileList[audioId]!.setupAudio(audioFilePath: urlString!, channelSettings: channelSettings)
                call.success(buildBaseResponse(wasSuccessful: true, message: "file is initialized", data: ["value": audioId]))
            }
            else {
                call.resolve(buildBaseResponse(wasSuccessful: false, message: "in initAudioFile, urlString invalid"))
            }
        }
        else {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "in initAudioFile, filePath invalid"))
        }
    }
    
    // MARK: destroyAudioFile
    @objc func destroyAudioFile(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        guard let audioId = getAudioId(call: call, functionName: "isPlaying") else {return}
        let response = audioFileList[audioId]!.destroy()
        audioFileList[audioId] = nil
        call.success(buildBaseResponse(wasSuccessful: true, message: "Audio file \(audioId) destroyed", data: response))
    }
    
    // MARK: isPlaying
    @objc func isPlaying(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        guard let audioId = getAudioId(call: call, functionName: "isPlaying") else {return}
        let result = audioFileList[audioId]!.isPlaying()
        call.success(buildBaseResponse(wasSuccessful: true, message: "audio file is playing", data: ["value": result]))
    }
    

    
    
    // This plays AND pauses stuff, ya daangus!
    // TODO: Return error to user when play is hit before choosing file
    
    // MARK: play RENAME ME TO PLAYORPAUSE
    @objc func play(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        guard let audioId = getAudioId(call: call, functionName: "play") else {return}
        let result = audioFileList[audioId]!.playOrPause()
        call.success(buildBaseResponse(wasSuccessful: true, message: "playing or pausing playback", data: ["state": result]))
    }
    
    // MARK: stop
    @objc func stop(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        guard let audioId = getAudioId(call: call, functionName: "stop") else {return}
        let result = audioFileList[audioId]!.stop()
        call.success(buildBaseResponse(wasSuccessful: true, message: "stopping playback", data: ["state": result]))
    }
    
    // MARK: adjustVolume
    @objc func adjustVolume(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        guard let audioId = getAudioId(call: call, functionName: "adjustVolume") else {return}
        let volume = call.getFloat("volume") ?? -1.0
        let inputType = call.getString("inputType")
        
        
        if (volume.isLess(than: 0)) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "in adjustVolume - volume cannot be less than zero percent"))
            return
        }
        if (inputType == "file") {
            audioFileList[audioId]?.adjustVolume(volume: volume)
        }
        else if (inputType == "mic") {
            micInputList[audioId]?.adjustVolume(volume: volume)
        }
        else {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "Could not find object at [audioId]"))
            return
        }
        call.success(buildBaseResponse(wasSuccessful: true, message: "you are adjusting the volume"))
    }
    
    // MARK: getCurrentVolume
    @objc func getCurrentVolume(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        guard let audioId = getAudioId(call: call, functionName: "getCurrentVolume") else {return}
        let inputType = call.getString("inputType")

        var result: Float?
        if (inputType == "file") {
            result = audioFileList[audioId]?.getCurrentVolume()
        }
        else if (inputType == "mic") {
            result = micInputList[audioId]?.getCurrentVolume()
        }
        else {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "Could not find object at [audioId]"))
            return
        }
        call.success(buildBaseResponse(wasSuccessful: true, message: "here is the current volume", data: ["volume": result ?? -1]))
    }
    
    // MARK: adjustEq
    @objc func adjustEq(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        guard let audioId = getAudioId(call: call, functionName: "adjustEq") else {return}
        let filterType = call.getString("eqType") ?? ""
        let gain = call.getFloat("gain") ?? -100.0
        let freq = call.getFloat("frequency") ?? -1.0
        let inputType = call.getString("inputType")
        
        
        if (filterType.isEmpty) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "from adjustEq - filter type not specified"))
            return
        }
        if (gain.isLess(than: -100.0)) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "from adjustEq - gain too low"))
            return
        }
        if (freq.isLess(than: -1.0)) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "from adjustEq - frequency not specified"))
            return
        }
        if (inputType == "file") {
            audioFileList[audioId]?.adjustEq(type: filterType, gain: gain, freq: freq)
        }
        else if (inputType == "mic") {
            micInputList[audioId]?.adjustEq(type: filterType, gain: gain, freq: freq)
        }
        else {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "Could not find object at [audioId]"))
            return
        }
        call.success(buildBaseResponse(wasSuccessful: true, message: "you are adjusting EQ"))
    }
    
    // MARK: getCurrentEq
    @objc func getCurrentEq(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        guard let audioId = getAudioId(call: call, functionName: "getCurrentEq") else {return}
        let inputType = call.getString("inputType")
        
        var result: [String: Float] = [:]
        if (inputType == "file") {
            result = (audioFileList[audioId]?.getCurrentEq())!
        }
        else if (inputType == "mic") {
            result = (micInputList[audioId]?.getCurrentEq())!
        }
        else {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "Could not find object at [audioId]"))
            return
        }
        call.success(buildBaseResponse(wasSuccessful: true, message: "here is the current EQ", data: result))
    }
    

    
    // MARK: setElapsedTimeEvent
    @objc func setElapsedTimeEvent(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        guard let audioId = getAudioId(call: call, functionName: "setElapsedTimeEvent") else {return}
        let eventName = call.getString("eventName") ?? ""
        if (eventName.isEmpty) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "from setElapsedTimeEvent - eventName not found"))
            return
        }
        audioFileList[audioId]?.setElapsedTimeEvent(eventName: eventName)
        call.success(buildBaseResponse(wasSuccessful: true, message: "set elapsed time event"))
    }
    
    // MARK: getElapsedTime
    @objc func getElapsedTime(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        guard let audioId = getAudioId(call: call, functionName: "getElapsedTime") else {return}
        let result = (audioFileList[audioId]?.getElapsedTime())!
        call.success(buildBaseResponse(wasSuccessful: true, message: "got Elapsed Time", data: result))
    }
    
    // MARK: getTotalTime
    @objc func getTotalTime(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        guard let audioId = getAudioId(call: call, functionName: "getTotalTime") else {return}
        let result = (audioFileList[audioId]?.getTotalTime())!
        call.success(buildBaseResponse(wasSuccessful: true, message: "got total time", data: result))
    }
    
    // MARK: getInputChannelCount
    @objc func getInputChannelCount(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        let channelCount = engine.inputNode.inputFormat(forBus: 0).channelCount;
        let deviceName = audioSession.preferredInput?.portName
        call.success(buildBaseResponse(wasSuccessful: true, message: "got input channel count and device name", data: ["channelCount": channelCount, "deviceName": deviceName ?? ""]))
    }
    
    //6.14 CHANGED ERROR CHECKING TO INCLUDE MICINPUTLIST
    // MARK: getAudioId
    private func getAudioId(call: CAPPluginCall, functionName: String) -> String? {
        let audioId = call.getString("audioId") ?? ""
        if (audioId.isEmpty) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "from \(functionName) - audioId not found"))
            return nil
        }
        if (audioFileList[audioId] == nil && micInputList[audioId] == nil) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "from \(functionName) - File not yet added to queue"))
            return nil
        }
        return audioId
    }
    
    private func buildBaseResponse(wasSuccessful: Bool, message: String, data: [String: Any] = [:]) -> [String: Any] {
        if (wasSuccessful) {
            return ["status": "success", "message": message, "data": data]
        }
        else {
            return ["status": "error", "message": message, "data": data]
        }
    }
    
    private func checkAudioSessionInit(call: CAPPluginCall) -> Bool? {
        if (isAudioSessionActive == false) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "Must call initAudioSession prior to any other usage"))
            return nil
        }
        return true
    }
    
    private func determineAudioSessionPortDescription(desc: AVAudioSessionPortDescription, type: String) -> Bool {
        switch type {
            case "avb":
                if #available(iOS 14.0, *) {
                    return desc.portType == .AVB
                } else {
                    return false
                }
                
            case "hdmi":
                return desc.portType == .HDMI
                
            case "pci":
                if #available(iOS 14.0, *) {
                    return desc.portType == .PCI
                } else {
                    return false
                }
                
            case "airplay":
                return desc.portType == .airPlay
                
            case "bluetoothA2DP":
                return desc.portType == .bluetoothA2DP
                
            case "bluetoothHFP":
                return desc.portType == .bluetoothHFP
                
            case "bluetoothLE":
                return desc.portType == .bluetoothLE
                
            case "builtInMic":
                return desc.portType == .builtInMic
                
            case "builtInReceiver":
                return desc.portType == .builtInReceiver
                
            case "builtInSpeaker":
                return desc.portType == .builtInSpeaker
                
            case "carAudio":
                return desc.portType == .carAudio
                
            case "displayPort":
                if #available(iOS 14.0, *) {
                    return desc.portType == .displayPort
                } else {
                    return false
                }
                
            case "firewire":
                if #available(iOS 14.0, *) {
                    return desc.portType == .fireWire
                } else {
                    return false
                }
                
            case "headphones":
                return desc.portType == .headphones
                
            case "headsetMic":
                return desc.portType == .headsetMic
                
            case "lineIn":
                return desc.portType == .lineIn
                
            case "lineOut":
                return desc.portType == .lineOut
                
            case "thunderbolt":
                if #available(iOS 14.0, *) {
                    return desc.portType == .thunderbolt
                } else {
                    return false
                }
                
            case "usbAudio":
                return desc.portType == .usbAudio
                
            case "virtual":
                if #available(iOS 14.0, *) {
                    return desc.portType == .virtual
                } else {
                    return false
                }
                
            default:
                return false
        }
    }
    
    // TODO: Think about removing this observer when audioSession.isActive is set to false
    private func registerForSessionInterrupts() {
//        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: audioSession)
    }
    
    // TODO: Think about removing this observer when audioSession.isActive is set to false
    private func registerForSessionRouteChange() {
//        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: audioSession)
    }
    
    private func registerForMediaServicesWereReset() {
        nc.addObserver(self, selector: #selector(handleServiceReset), name: AVAudioSession.mediaServicesWereResetNotification, object: audioSession)
    }
    
    private func registerForMediaServicesWereLost() {
        nc.addObserver(self, selector: #selector(handleServiceLost), name: AVAudioSession.mediaServicesWereLostNotification, object: audioSession)
    }
    
    // MARK: handleRouteChange
    @objc func handleRouteChange(notification: Notification) {
//        DispatchQueue.main.async {
        print("handleRouteChange occurred with notification: \(notification)")
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
        else {return}
        switch reason {
            case .oldDeviceUnavailable:
                print("Old device unavailable")
                self.notifyListeners(self.audioSessionListenerName, data: ["handlerType": "ROUTE_DEVICE_DISCONNECTED"])
                self.micInputList.forEach { (key: String, value: MicInput) in
                    value.interrupt()
                }
            case .newDeviceAvailable:
                print("New device is available!")
                self.notifyListeners(self.audioSessionListenerName, data: ["handlerType": "ROUTE_DEVICE_RECONNECTED"])
                self.micInputList.forEach { (key: String, value: MicInput) in
                    value.resumeFromInterrupt()
                }
            case .routeConfigurationChange:
                print("Route has changed")
                self.notifyListeners(self.audioSessionListenerName, data: ["handlerType": ""])
            case .noSuitableRouteForCategory:
                print("No suitable route for category.")
            case .override:
                print("Route overridden")
                if let inputDesc = audioSession.availableInputs?.first(where: {(desc) -> Bool in
                    print("Available Input: ", desc)
                    return desc.portType == .usbAudio
                }) {
                    do {
        //                try audioSession.setActive(false)
                        try audioSession.setPreferredInput(inputDesc)
        //                try audioSession.setActive(true)
                    } catch let error {
//                        isAudioSessionActive = false
//                        call.resolve(buildBaseResponse(wasSuccessful: false, message: "There was a problem initializing your audio session with exception: \(error)"))
                        print(error)
                        return
                    }
                }
            case .categoryChange:
                print("Category has changed.")
            case .unknown:
                print("unknown: issa big mystery!")
            case .wakeFromSleep:
                print("Hello world!")
            default:
                ()
            }
//        }
    }
    
    // MARK: handleInterruption
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else {return}
        
        switch type {
        case .began:
            print("AudioSession interrupted!")
            audioFileList.forEach{ (key: String, value: AudioFile) in
                if (value.isPlaying()) {
                    value.player.pause()
                    self.audioFileInterruptionList.append(key)
                }
            }
            notifyListeners(audioSessionListenerName, data: ["handlerType": "INTERRUPT_BEGAN"])
        case .ended:
            print("AudioSession resuming...")
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {return}
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if (options.contains(.shouldResume)) {
                self.audioFileInterruptionList.forEach{ (key: String) in
                    self.audioFileList[key]!.player.play()
                }
                audioFileInterruptionList = []
            } else {
                //An interruption ended. Don't resume playback.
            }
            notifyListeners(audioSessionListenerName, data: ["handlerType": "INTERRUPT_ENDED"])
        default:
            ()
        }
    }
    
    @objc func handleServiceReset(notification: Notification) {
//        guard let userInfo = notification.userInfo,
//              let typeValue = userInfo[AVAudioSession] as? UInt,
//              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
//        else {return}
        print("From handleServiceReset - Notification is: \(notification)")
    }
    
    @objc func handleServiceLost(notification: Notification) {
        print("From handleServiceLost - Notification is: \(notification)")
    }
    
}
