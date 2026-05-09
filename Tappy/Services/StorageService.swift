import Foundation
import Observation

@Observable
final class StorageService {

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = .prettyPrinted
        encoder = enc

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        decoder = dec
    }

    // MARK: - Paths

    private var appSupportURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Tappy", isDirectory: true)
    }

    private var recordingsDirectoryURL: URL {
        appSupportURL.appendingPathComponent("recordings", isDirectory: true)
    }

    private func recordingFileURL(id: UUID) -> URL {
        recordingsDirectoryURL.appendingPathComponent("\(id.uuidString).json")
    }

    private var playbackConfigURL: URL {
        appSupportURL.appendingPathComponent("playback-config.json")
    }

    // MARK: - MacroRecording CRUD

    func saveRecording(_ recording: MacroRecording) throws {
        try FileManager.default.createDirectory(
            at: recordingsDirectoryURL, withIntermediateDirectories: true)
        let data = try encoder.encode(recording)
        try data.write(to: recordingFileURL(id: recording.id), options: .atomic)
    }

    func loadAllRecordings() throws -> [MacroRecording] {
        let dir = recordingsDirectoryURL
        guard FileManager.default.fileExists(atPath: dir.path) else { return [] }

        let urls = try FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }

        return urls.compactMap { url in
            do {
                let data = try Data(contentsOf: url)
                return try decoder.decode(MacroRecording.self, from: data)
            } catch {
                print("[StorageService] Skipping \(url.lastPathComponent): \(error)")
                return nil
            }
        }.sorted { $0.createdAt > $1.createdAt }
    }

    func deleteRecording(id: UUID) throws {
        let url = recordingFileURL(id: id)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw StorageError.fileNotFound(id: id)
        }
        try FileManager.default.removeItem(at: url)
    }

    func updateRecording(_ recording: MacroRecording) throws {
        let url = recordingFileURL(id: recording.id)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw StorageError.fileNotFound(id: recording.id)
        }
        let data = try encoder.encode(recording)
        try data.write(to: url, options: .atomic)
    }

    // MARK: - PlaybackConfig

    func savePlaybackConfig(_ config: PlaybackConfig) throws {
        try FileManager.default.createDirectory(
            at: appSupportURL, withIntermediateDirectories: true)
        let data = try encoder.encode(config)
        try data.write(to: playbackConfigURL, options: .atomic)
    }

    func loadPlaybackConfig() throws -> PlaybackConfig {
        let url = playbackConfigURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            return .default
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode(PlaybackConfig.self, from: data)
    }
}

enum StorageError: Error {
    case directoryCreationFailed
    case encodingFailed
    case decodingFailed(filename: String, underlying: Error)
    case fileNotFound(id: UUID)
}
