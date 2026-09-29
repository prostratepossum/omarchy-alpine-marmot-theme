# Starwatch colors for eza (ls/lt): sky dirs, meadow executables, firefly sizes,
# rose write bits, muted dates — matches the Alpine Marmot theme.
export EZA_COLORS="di=1;38;2;100;124;214:ex=1;38;2;83;189;82:ln=38;2;87;173;208:or=38;2;224;132;143:\
sn=38;2;227;220;92:sb=38;2;138;135;88:da=38;2;103;106;112:uu=38;2;184;180;117:gu=38;2;138;135;88:\
ur=38;2;227;220;92:uw=38;2;224;132;143:ux=38;2;83;189;82:ue=38;2;83;189;82:\
gr=38;2;138;135;88:gw=38;2;176;110;118:gx=38;2;60;130;60:tr=38;2;138;135;88:tw=38;2;176;110;118:tx=38;2;60;130;60:\
xx=38;2;77;86;134:ga=38;2;83;189;82:gm=38;2;227;220;92:gd=38;2;224;132;143:gn=38;2;184;172;245"
# Starwatch fzf (Ctrl+R history, Ctrl+T files, Alt+C dirs, `ff`): transparent
# background, sky border, firefly match highlights, ✦ pointer like the prompt.
export FZF_DEFAULT_OPTS="\
--color=bg:-1,bg+:#1c263f,fg:#B8B475,fg+:#d7d581,hl:#e3dc5c,hl+:#f0ea80 \
--color=border:#4d5686,label:#869dff,prompt:#647cd6,pointer:#e3dc5c,marker:#53bd52 \
--color=spinner:#9d8fe6,info:#676a70,header:#9d8fe6,query:#d7d581,gutter:-1,scrollbar:#4d5686 \
--layout=reverse --border=rounded --border-label=' ✦ starwatch ' --border-label-pos=3 \
--prompt='☾ ' --pointer='✦' --marker='+' --info=inline-right --height=45%"
