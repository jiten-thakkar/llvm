; RUN: llc -march=amdgcn -mcpu=SI -verify-machineinstrs < %s | FileCheck -check-prefix=FUNC -check-prefix=SI %s

@ptr_load = addrspace(3) global i32 addrspace(2)* undef, align 8

; Make sure when the load from %ptr2 is folded the chain isn't lost,
; resulting in losing the store to gptr

; FUNC-LABEL: {{^}}missing_store_reduced:
; SI: s_load_dwordx2
; SI: ds_read_b64
; SI-DAG: buffer_store_dword
; SI-DAG: v_readfirstlane_b32 s[[PTR_LO:[0-9]+]], v{{[0-9]+}}
; SI: v_readfirstlane_b32 s[[PTR_HI:[0-9]+]], v{{[0-9]+}}
; SI: s_nop 3
; SI: s_load_dword s{{[0-9]+}}, s{{\[}}[[PTR_LO]]:[[PTR_HI]]{{\]}}
; SI: buffer_store_dword
; SI: s_endpgm
define void @missing_store_reduced(i32 addrspace(1)* %out, i32 addrspace(1)* %gptr) #0 {
  %ptr0 = load i32 addrspace(2)*, i32 addrspace(2)* addrspace(3)* @ptr_load, align 8
  %ptr2 = getelementptr inbounds i32, i32 addrspace(2)* %ptr0, i64 2

  store i32 99, i32 addrspace(1)* %gptr, align 4
  %tmp2 = load i32, i32 addrspace(2)* %ptr2, align 4

  store i32 %tmp2, i32 addrspace(1)* %out, align 4
  ret void
}

attributes #0 = { nounwind }

