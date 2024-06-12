import os
import re
import subprocess
import urllib.request
from bs4 import BeautifulSoup

import keys

WORKSHOP = "steamapps/workshop/content/107410/"
USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.47 Safari/537.36"  # noqa: E501


def install_mod(id_list):
    steamcmd = ["/usr/games/steamcmd"]
    steamcmd.extend(["+force_install_dir", "/arma3"])
    steamcmd.extend(["+login", os.environ["STEAM_USER"], os.environ["STEAM_PASSWORD"]])
    for id in id_list:
        steamcmd.extend(["+workshop_download_item", "107410", id])
    steamcmd.extend(["+workshop_download_item", "107410", id])
    steamcmd.extend(["+quit"])
    subprocess.call(steamcmd)

def dir_rename_to_lower_recursive(dir):
    def rename_all(path, items):
        for name in items:
            try:
                os.rename(os.path.join(path,name),
                os.path.join(path, name.lower()))
            except OSError:
                pass

    for path,subdirs,files in os.walk(dir, topdown=False):
        rename_all(path, files)
        rename_all(path, subdirs)

def preset(mod_file):
    modslist = []
    mod_json = {}
    if mod_file.startswith("http"):
        req = urllib.request.Request(
            mod_file,
            headers={"User-Agent": USER_AGENT},
        )
        remote = urllib.request.urlopen(req)
        with open("preset.html", "wb") as f:
            f.write(remote.read())
        mod_file = "preset.html"
    with open(mod_file) as f:
        table_data = [[cell.text for cell in row("td")]
            for row in BeautifulSoup(f, "html.parser")("tr")]
    for mod in table_data:
        regex = r"filedetails\/\?id=(\d+)"
        match = re.search(regex, mod[2])
        mod_json[match.group(1)] = '@' + mod[0].lower().replace(' ','_')
    install_mod(mod_json)
    for id in mod_json:
        moddir = WORKSHOP + id
        keys.copy(moddir)
        if os.path.exists(mod_json[id]):
            os.remove(mod_json[id])
        os.symlink(moddir, mod_json[id])
        modslist.append(mod_json[id])
    dir_rename_to_lower_recursive(WORKSHOP)
    return modslist
