#pragma once

#include <vector>
#include <set>
#include <map>
#include <string>

#include "option.h"

class FirebaseConfig {
    std::string project_id;
    std::set<std::string> privileged_uids;
    std::map<std::string, std::vector<std::uint8_t>> public_keys;
public: 

    FirebaseConfig() = default;
    FirebaseConfig(const FirebaseConfig&) = default;
    FirebaseConfig(FirebaseConfig&&);

    FirebaseConfig& operator=(const FirebaseConfig&) = default;
    FirebaseConfig& operator=(FirebaseConfig&&);

    static bool from_json_file(const std::string& path, FirebaseConfig& config);

    const std::string& get_project_id() const;
    bool contains_uid(const std::string& uid) const;
    Option<std::vector<std::uint8_t> const *> find_public_key(const std::string& key_id) const;

    bool is_configured() const;
};