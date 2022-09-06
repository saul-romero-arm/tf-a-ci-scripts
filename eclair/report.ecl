# eclair_report

#defun(sel_violations(s),
#  create_sel(s,
#             [["clear_all",s],
#              ["add_kind",s,"violation"],
#              ["add_kind",s,"error"],
#              ["select_kind","",s],
#              ["reset",s],
#              ["add_service_glob",s,"B.EXPLAIN"],
#              ["select_service","",s]]),
#  sel(s))
#
#defun(sel_samples(s,count,domain1,domain2),
#  untag("sample","true"),
#  tag_samples("sample","true",count,domain1,domain2),
#  sel_tag_glob(s,"sample","true"),
#  sel(s))
#
#sel_violations("violations_selection")
#sel_samples("samples_selection",20,"first_file","service")
#save_sel()
