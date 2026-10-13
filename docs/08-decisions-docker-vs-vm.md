# 8. Justificació tecnològica: Docker en lloc de màquines virtuals

| | Una VM per servei | Docker Compose |
|---|---|---|
| Recursos | Un SO complet per servei | Kernel compartit, MBs per contenidor |
| Desplegament | Instal·lar i configurar a mà | `./deploy.sh up` (reproduïble) |
| Configuració | Dins de cada VM, difícil de versionar | Fitxers al repositori Git |
| Còpia a un company | Exportar/importar OVA | `git clone` + `./deploy.sh up` |
| Aïllament | Alt (hipervisor) | Mitjà (namespaces/cgroups) |

## Limitacions conegudes
- **Windows**: no és un contenidor Linux; s'ofereix un perfil experimental (`dockurr/windows`, requereix KVM) o una VM.
- **DHCP**: els contenidors reben IP fixa de Docker; el servidor DHCP funciona i es valida amb un DISCOVER (nmap) i amb clients reals a la mateixa xarxa.
- **Contenidors ≠ màquines**: no tenen `systemd`; cada servei corre en primer pla amb sshd al costat per complir l'accés `bchecker`.
- **Networking**: les xarxes DMZ i Intranet són *bridges* de Docker i el router és un contenidor més; l'aïllament fort entre xarxes depèn de les regles del router.
