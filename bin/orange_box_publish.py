#!/usr/bin/env python3

"""Short script to read in analysis_ids from a list of analysis_id files
associated with Orange box analyses for a given a climb_id and publish these
analyses on Onyx.  When the script is run, all modules will have fully
updated Onyx analyses and all relevant results files will have successfully
transferred to S3.

Inputs:
  --climb_id:          climb_id
  --server:            {mscape, synthscape}
  --analysis_id_files: comma-separated list of analysis_ids to publish to Onyx
                       in the form ${climb_id}.${orange_box_module}.analysis_id

Example of command to run script:
python orange_portal.py --climb_id ID-12345678  --server mscape  \
    --analysis_id_files \
    ID-12345678.QC.analysis_id,ID-12345678.virus_reclassification.analysis_id
"""

from onyx_analysis_helper import onyx_analysis_helper_functions as oa
import argparse
import logging
import sys
from pathlib import Path


def get_args():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(
        prog="Orange Box Onyx analysis publisher",
        description="""Script to run after Orange box module has finished
        updating all Onyx analyses and uploaded all results files to S3.
        On successful completion will have published Onyx analyses for all
        Orange Box modules.
        """
    )
    parser.add_argument(
        "--server",
        "-s",
        type=str,
        required=True,
        choices=["mscape", "synthscape"],
        help="Specify server code is being run on",
    )
    parser.add_argument("--climb_id", "-c", type=str, required=True, help="Climb_id")
    parser.add_argument("--analysis_id_files", "-a", type=str, required=True, help="Comma-separated list of analysis_ids to publish to Onyx")

    return parser.parse_args()


def set_up_logger(stdout_file):
    """Creates logger for component - all logging messages go to stdout
    log file, error messages also go to stderr log. If component runs
    correctly, stderr is empty.
    """
    logger = logging.getLogger()
    logger.setLevel(logging.DEBUG)
    formatter = logging.Formatter("[%(asctime)s] %(levelname)s: %(message)s")

    out_handler = logging.FileHandler(stdout_file, mode="a")
    out_handler.setFormatter(formatter)
    logger.addHandler(out_handler)

    return logger


def read_analysis_id_from_file(analysis_id_file):
    """Function to read analysis_id from analysis_id file and return an error if
    there is not exactly one analysis_id contained in the file.
    """
    exitcode = 0
    try:
        with open(analysis_id_file, "r") as infile:
            lines = [line.rstrip() for line in infile]
            # Check analysis_id file contains only one analysis_id
            if len(lines) == 1:
                analysis_id = lines[0]
            else:
                logging.error("Analysis_id_file should contain 1 line: %s contained %s lines", analysis_id_file, len(lines))
                exitcode = 1
                return None, exitcode
    except:
        logging.error("Couldn't read analysis_id from file: %s", analysis_id_file)
        exitcode = 1
        return None, exitcode

    return analysis_id, exitcode


# Main
""" Data flow reminder:
Assume upstream Onyx/S3 transfer processes have successfully completed
and created final analysis_id files, one per Orange Box module.
Tasks for this script:
  (1) Read in analysis_ids from analysis_id_files;
      these are named as: ${climb_id}.${orange_box_module}.analysis_id
  (2) For each analysis_id, perform the final write-to-onyx step and PUBLISH
"""
def main():
    args = get_args()
    exitcode = 0

    # Set up log file
    log_file = f"{args.climb_id}.Orange_Box_Onyx_publish_log.txt"
    set_up_logger(log_file)
    # Create empty list to store analysis_ids from analysis_id_files
    # and dictionary to map analysis_ids to their analysis_id_files for troubleshooting
    analysis_ids = list()
    analysis_id_to_file = dict()

    # Read analysis_ids from each analysis_id_file in analysis_id_files
    for analysis_id_file in args.analysis_id_files.split(','):
        analysis_id, exitcode = read_analysis_id_from_file(analysis_id_file)
        if exitcode != 0:
            logging.error("Unable to read analysis_id from analysis_id_file: %s", analysis_id_file)
        else:
        # Add the analysis_id to the list and store link between analysis_id and analysis_id_file
            analysis_ids.append(analysis_id)
            analysis_id_to_file[analysis_id] = analysis_id_file

    # Make script die after attempting to load all analysis_id files
    # and not die after the first fail
    if exitcode != 0:
        logging.error("Unable to read one or more analysis_id_files: check log file for details")
        return exitcode
    # Sanity check for now - ensure the number of analysis IDs in the list
    # is the same as the number of analysis_id_files:
    if len(analysis_ids) != len(args.analysis_id_files.split(',')):
        exitcode = 1
        logging.error("Unexpected error: number of analysis_ids didn't match number of analysis_id files: %s",
                      args.analysis_id_files)
        return exitcode

    for analysis_id in analysis_ids:
        onyx_analysis = oa.OnyxAnalysis()
        # Final write to Onyx - publishing a skeleton Onyx Analysis object for each analysis
        analysis_id_json, exitcode = onyx_analysis.update_onyx_analysis(server=args.server, analysis_id=analysis_id, dryrun=False, publish_analysis=True)

        if exitcode != 0:
            logging.error("Onyx publish step failed for: %s using analysis_id: %s loaded from: %s on: %s",
                         args.climb_id, analysis_id, analysis_id_to_file[analysis_id], args.server)

    if exitcode != 0:
        logging.error("Incomplete Onyx publish step - one or more analyses failed to publish: check log file for details")
        return exitcode

    # End of all publish steps - if we get this far everything should have worked...
    logging.info("All Onyx publish steps completed")
    return exitcode


if __name__ == "__main__":
    sys.exit(main())
