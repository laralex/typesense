#include <fstream>
#include "firebase_config.h"
#include "json.hpp"


FirebaseConfig::FirebaseConfig(FirebaseConfig&& other) : project_id(other.project_id), 
                                                         privileged_uids(other.privileged_uids),
                                                         public_keys(other.public_keys) { 

}

FirebaseConfig& FirebaseConfig::operator=(FirebaseConfig&& other) { 
    project_id = other.project_id;
    other.privileged_uids = other.privileged_uids;
    public_keys = other.public_keys;
    return *this;
}

bool FirebaseConfig::from_json_file(const std::string& path, FirebaseConfig& config) {

    std::ifstream config_file(path);
    using stream_iter = std::istreambuf_iterator<char>;
    std::string config_content((stream_iter(config_file)), stream_iter());

    nlohmann::json config_json;
    try {
        config_json = nlohmann::json::parse(config_content);
    } catch(const std::exception& e) {
        //LOG(ERROR) << "JSON error: " << e.what();
        return false;
    }

    if (config_json.count("project_id") == 0 || !config_json["project_id"].is_string() ||
        config_json.count("privileged_firebase_uids") == 0 ||
        config_json.count("public_keys_ids") == 0 || !config_json["public_keys_ids"].is_array() || config_json["public_keys_ids"].size() == 0 || 
        config_json.count("public_keys_files") == 0 || !config_json["public_keys_files"].is_array() || 
        config_json["public_keys_files"].size() != config_json["public_keys_ids"].size())  {
        return false;
    }

    std::set<std::string> uids;
    for(const auto& uid_candidate : config_json["privileged_firebase_uids"]) {
        if (!uid_candidate.is_string()) {
            return false;
        }
        uids.emplace(uid_candidate.dump());
    }

    std::map<std::string, std::vector<std::uint8_t>> public_keys;
    auto& keys_ids = config_json["public_keys_ids"];
    auto& keys_files = config_json["public_keys_files"];
    for(std::size_t i = 0; i < keys_ids.size(); ++i) {
        if (!keys_ids[i].is_string() || !keys_files[i].is_string()){
            return false;
        }
        try {
            std::ifstream key_file(keys_files[i].dump(), std::ios::binary | std::ios::ate);
            std::ifstream::pos_type pos = key_file.tellg();
            std::vector<uint8_t> key_bytes(pos);

            key_file.seekg(0, std::ios::beg);
            key_file.read(reinterpret_cast<char *>(&key_bytes[0]), pos);

            public_keys.emplace(keys_ids[i].dump(), std::move(key_bytes));
        } catch(const std::exception& e) {
            return false;
        }
    }

    FirebaseConfig result_config;
    result_config.project_id = config_json["project_id"].dump();
    result_config.privileged_uids = std::move(uids);
    result_config.public_keys = std::move(public_keys);
    return true;
}

const std::string& FirebaseConfig::get_project_id() const {
    return project_id;
}

bool FirebaseConfig::contains_uid(const std::string& uid) const {
    return privileged_uids.find(uid) != privileged_uids.end();
}


Option<std::vector<std::uint8_t> const *> FirebaseConfig::find_public_key(const std::string& key_id) const {
    auto pub_key_cursor = public_keys.find(key_id);
    if (pub_key_cursor != public_keys.end()) {
        return Option<std::vector<std::uint8_t> const *>(&(pub_key_cursor->second));
    }
    return Option<std::vector<std::uint8_t> const *>(404, "firebase_public_key_unknown");
}

bool FirebaseConfig::is_configured() const {
    return !public_keys.empty() && !project_id.empty();
}