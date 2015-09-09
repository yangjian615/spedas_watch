Pro fa_esa_clear_common_blocks, l1 = l1, l2 = l2

  If(keyword_set(l2)) Then Begin
     common fa_ies_l2, get_ind_ies, all_dat_ies
     get_ind_ies = 0 & all_dat_ies = -1
     common fa_ees_l2, get_ind_ees, all_dat_ees
     get_ind_ees = 0 & all_dat_ees = -1
     common fa_ieb_l2, get_ind_ieb, all_dat_ieb
     get_ind_ieb = 0 & all_dat_ieb = -1
     common fa_eeb_l2, get_ind_eeb, all_dat_eeb
     get_ind_eeb = 0 & all_dat_eeb = -1
  Endif Else If(keyword_set(l1)) Then Begin
     common fa_ies_l1, get_ind_ies, all_dat_ies
     get_ind_ies = 0 & all_dat_ies = -1
     common fa_ees_l1, get_ind_ees, all_dat_ees
     get_ind_ees = 0 & all_dat_ees = -1
     common fa_ieb_l1, get_ind_ieb, all_dat_ieb
     get_ind_ieb = 0 & all_dat_ieb = -1
     common fa_eeb_l1, get_ind_eeb, all_dat_eeb
     get_ind_eeb = 0 & all_dat_eeb = -1
  Endif Else Begin
     common fa_ies_l1, get_ind_ies, all_dat_ies
     get_ind_ies = 0 & all_dat_ies = -1
     common fa_ees_l1, get_ind_ees, all_dat_ees
     get_ind_ees = 0 & all_dat_ees = -1
     common fa_ieb_l1, get_ind_ieb, all_dat_ieb
     get_ind_ieb = 0 & all_dat_ieb = -1
     common fa_eeb_l1, get_ind_eeb, all_dat_eeb
     get_ind_eeb = 0 & all_dat_eeb = -1
  Endelse

End
