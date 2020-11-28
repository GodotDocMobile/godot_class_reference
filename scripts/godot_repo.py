#!/usr/bin/python3

from git import Repo
import xml.etree.ElementTree as ET
from os.path import isfile, join, exists
from os import listdir, mkdir, remove
import re
from shutil import copyfile
import datetime
import yaml
import json
import argparse

branches = [
    "2.0",
    "2.1",
    "3.0",
    "3.1",
    "3.2"
]

godot_repo = "/home/tin/Projects/godot"


class ClassNode:
    inherit_chain = ""
    class_name = ""
    parent_class = ""

    def __init__(self, name, parent_class=''):
        self.class_name = name
        self.parent_class = parent_class
        pass

    @staticmethod
    def parse_element(element):
        if 'inherits' in element.attrib:
            return ClassNode(element.attrib['name'], element.attrib['inherits'])
        else:
            return ClassNode(element.attrib['name'])

# TODO: add inherit chain on each classes.
# TODO: update svg files


def _write_file_index(branch_name, file_name_arr):
    file_name_arr.sort()
    files_json = json.dumps(file_name_arr)
    f = open(join("../xmls", "files_"+branch_name+".json"), "w")
    f.write(files_json)
    f.close()
    pass


def _remove_old_files(folder_path, branch_name):
    if exists(folder_path):
        print("removing old xml files...")
        for xml in listdir(folder_path):
            remove(join(folder_path, xml))
            pass
        pass
        print("done removing")
    else:
        print("create folder for "+branch_name)
        mkdir(folder_path)
    pass


def _copy_and_strip(src_path, dest_path):
    _f = open(src_path, 'r')
    _content = _f.read()
    _f.close()

    _f = open(dest_path, 'w')
    _f.write(re.sub('\n[\t]*<', '<', re.sub('>\n[\t]*<', '><', _content)))
    _f.close()
    pass


def find_child_classes(class_list, name):
    _return_list = []
    for c in class_list:
        if c.parent_class == name:
            _return_list.append(c)
            _return_list = _return_list + find_child_classes(class_list, c.class_name)
    return _return_list


def single_class_files(branch_name):
    _classes = []
    _nodes = [ClassNode(name='Node')]
    # remove old files
    _folder_path = join("../xmls", branch_name)
    _remove_old_files(_folder_path, branch_name)

    _files = []

    tree = ET.parse(join(godot_repo, "doc/base/classes.xml"))
    print("[{}] this branch only contains single file")
    # print(tree.getroot().getchildren())
    for n in tree.getroot().getchildren():
        print("[{}] dumping {}".format(branch_name, n.attrib["name"]))
        # print(ET.tostring(n,encoding="unicode"))
        f = open(join(_folder_path, n.attrib["name"]+".xml"), "w")
        f.write(re.sub('\n[\t]*<', '<', re.sub('>\n[\t]*<',
                                               '><', ET.tostring(n, encoding="unicode")[0:-1])))
        # print("done dumping")
        _files.append(n.attrib["name"]+".xml")
        _class = ClassNode.parse_element(n)
        _classes.append(_class)
    _nodes = _nodes + find_child_classes(_classes, 'Node')
    for n in _nodes:
        _index = _files.index("{}{}".format(n.class_name, ".xml"))
        _files[_index] = _files[_index].replace('.xml', '#Node#.xml')
    _write_file_index(branch_name, _files)


def multiple_class_files(branch_name):
    _classes = []
    _nodes = [ClassNode(name='Node')]

    _folder_path = join("../xmls", branch_name)
    _remove_old_files(_folder_path, branch_name)

    _files = []

    _class_docs_folder = join(godot_repo, "doc", "classes")
    print("[{}] this branch contains multiple files".format(branch_name))
    print("[{}] processing regular docs".format(branch_name))
    for origin_file in listdir(_class_docs_folder):
        print("[{}] procesing {}".format(branch_name, origin_file))

        _copy_and_strip(join(_class_docs_folder, origin_file),
                        join(_folder_path, origin_file))
        _files.append(origin_file)
        _xml_element = ET.parse(join(_folder_path, origin_file))
        _class = ClassNode.parse_element(_xml_element.getroot())
        _classes.append(_class)
        pass

    print("[{}] processing module docs".format(branch_name))
    _module = [m for m in listdir(join(godot_repo, "modules")) if not isfile(
        join(godot_repo, "modules", m))]
    for m in _module:
        _folder = join(godot_repo, "modules", m, "doc_classes")
        if exists(_folder):
            # print("[{}] module:{}".format(branch_name,m))
            _xmls = [f for f in listdir(_folder) if isfile(
                join(_folder, f)) and f[-4:] == '.xml']
            for _xml in _xmls:
                print("[{}] [module {}] processing {}".format(
                    branch_name, m, _xml))
                _copy_and_strip(join(_folder, _xml), join(_folder_path, _xml))
                _files.append(_xml)

                _xml_element = ET.parse(join(_folder_path, _xml))
                _class = ClassNode.parse_element(_xml_element.getroot())
                _classes.append(_class)
                pass
            pass
    _write_file_index(branch_name, _files)
    _nodes = _nodes + find_child_classes(_classes, 'Node')
    for n in _nodes:
        _index = _files.index("{}{}".format(n.class_name, ".xml"))
        _files[_index] = _files[_index].replace('.xml', '#Node#.xml')
    _write_file_index(branch_name, _files)


def parse_argv():
    parser = argparse.ArgumentParser(
        description="update godot documents and strip unnecessary line breaking")
    # parser.add_argument('-sp','--skip-pull',metavar='SP',help='skip pulling action before strip line breaking')
    parser.add_argument(
        '--skip_pull', help='skip pulling action before strip line breaking', action='store_true')
    return parser.parse_args()


if __name__ == "__main__":

    parsed = parse_argv()

    _doc_date = datetime.date.today() - datetime.timedelta(days=1)

    _config_content = []

    _time_line = 0
    _find_time_line = False
    with open("../pubspec.yaml", 'r') as f:
        for line in f:
            # print(line[0:10]=="doc_time: ")
            if line[0:10] == "doc_time: ":
                _find_time_line = True
            if not _find_time_line:
                _time_line += 1
            _config_content.append(line)
        pass

    if _find_time_line:
        _time_str = _config_content[_time_line][10:-1]
        _doc_date = datetime.datetime.strptime(_time_str, '%Y-%m-%d')
    else:
        # _time
        pass

    repo = Repo.init(godot_repo)

    _today = datetime.datetime.today()
    _today = _today - datetime.timedelta(hours=_today.hour, minutes=_today.minute,
                                         seconds=_today.second, microseconds=_today.microsecond)

    for b in branches:
        print("checking out branch " + b)
        repo.git.checkout(b)

        if not parsed.skip_pull:
            if _doc_date != _today:
                print("performing pull action from origin ...")
                o = repo.remotes.origin
                o.pull()
                print("done pulling.")

        if float(b) >= 3:
            multiple_class_files(b)
            pass
        else:
            single_class_files(b)
            pass
        pass

    _doc_date = datetime.date.today()
    # if _find_time_line:
    #     _config_content[_time_line] = 'doc_time: {}\n'.format(_doc_date)
    # else:
    #     _config_content.append('doc_time: {}\n'.format(_doc_date))

    # _config_file = open("../pubspec.yaml",'w')
    # _config_file.write("".join(_config_content))
    # _config_file.close()

    _update_doc_file = open("../xmls/conf.json", "w")
    _update_doc_file.write("{}".format(_doc_date))
    _update_doc_file.close()

    print("finish at {}".format(_doc_date))
