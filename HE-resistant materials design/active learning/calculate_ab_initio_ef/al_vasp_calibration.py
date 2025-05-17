import os
import sys
import shutil
sys.path.append("/scratch/yuchengji/script/python/")
from lib import VASP_Structure as VS

model_list = []

ele_model = VS.CfgRead('diff.cfg')

for files in os.listdir('.'):
    if 'outmodel' in files and not 'cfg' in files:
        model_list.append(files)

if len(model_list) > 30:
    model_num = 30
else:
    model_num = len(model_list)


for i in range(model_num):
    model = model_list[i]
    model_path = './mlp_al/%s' %(model)
    if not os.path.exists(model_path):
        os.makedirs(model_path)

    poscar = VS.Cfg2Poscar(model, ['Al', 'Sc', 'Cu', 'H'], ele_model[i])

    with open('%s/POSCAR' %(model_path), 'w') as psc_w:
        psc_w.write('\n'.join(poscar))

    shutil.copy('./raw_VASP_files/INCAR', '%s/INCAR' % (model_path))
    shutil.copy('./raw_VASP_files/KPOINTS', '%s/KPOINTS' % (model_path))
    shutil.copy('./raw_VASP_files/POTCAR', '%s/POTCAR' % (model_path))

    print("The %s model has been created" %(model))
