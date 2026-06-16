# some_file.py
import json
import logging
import shutil
import sys
from pathlib import Path

import pytest

repo_path = Path(__file__).resolve().parents[1]

sys.path.insert(1, str(Path(repo_path / "bin")))

import orange_box_onyx_s3

# Set up some test files
asset_path = Path(repo_path / "assets")

test_jsons = sorted(asset_path.glob("*.json"))


@pytest.mark.parametrize("test_json", test_jsons)
def test_add_orange_box_version_to_json(test_json, tmp_path):
    # copy the file so it can be edited
    file_name = test_json.name
    new_file_name = Path(tmp_path / file_name)
    shutil.copyfile(test_json, new_file_name)

    # run the function being tested
    orange_box_onyx_s3.add_orange_box_version_to_json(new_file_name, "1.0.0")

    # read in the edited file:
    versions_dict = {}
    with new_file_name.open() as new_json:
        analysis_json = json.load(new_json)

        # get the versions into a flattened dict

        methods: dict = json.loads(analysis_json["methods"])
        versions_list = methods["versions"]
        for version_dict in versions_list:
            versions_dict[version_dict["name"]] = version_dict["version"]

    assert versions_dict["orange_box_version"] == "1.0.0"
    assert (
        len(versions_dict.keys()) == 8
    )  # make sure the versions hasn't been overwritten


def test_add_orange_box_version_to_json_already_there(tmp_path, caplog):
    """Check that if the orange box version is already there, that it skips."""
    caplog.set_level(logging.DEBUG)
    json_with_version = Path(
        asset_path
        / "ID-12345678.claspar-krakenbacteria.analysis_fields_with_version.json"
    )
    exitcode = orange_box_onyx_s3.add_orange_box_version_to_json(
        json_with_version, "1.0.0"
    )
    assert exitcode == 0
    assert "Orange box version 1.0.0 already in json" in caplog.text
