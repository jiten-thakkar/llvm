; RUN: opt -instcombine -S < %s | FileCheck %s

define i32 @test(i32 %x) {
; CHECK-LABEL: @test
entry:
; CHECK-NOT: icmp
; CHECK: br i1 undef, 
  %cmp = icmp ult i32 %x, 7
  br i1 %cmp, label %merge, label %merge
merge:
; CHECK-LABEL: merge:
; CHECK: ret i32 %x
  ret i32 %x
}

define i32 @test1(i32 %c) {
; CHECK-LABEL: @test1
entry:
  %c.off = add i32 %c, -1
  %0 = icmp ult i32 %c.off, 4
  br i1 %0, label %if.then, label %return

if.then:
; CHECK-LABEL: if.then:
; CHECK-NOT: tail call
; CHECK-NOT: extractvalue { i32, i1 } %1, 0
; CHECK-NOT: extractvalue { i32, i1 } %1, 1
; CHECK: shl i32 %c
; CHECK: br i1
  %1 = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %c, i32 %c)
  %2 = extractvalue { i32, i1 } %1, 0
  %3 = extractvalue { i32, i1 } %1, 1
  br i1 %3, label %handler.add_overflow, label %return

handler.add_overflow:
; CHECK-LABEL: handler.add_overflow:
; CHECK-NOT: zext
; CHECK: br label
  %4 = zext i32 %c to i64
  br label %return

return:
; CHECK-LABEL: return:
  %retval.0 = phi i32 [ %2, %if.then ], [ %2, %handler.add_overflow ], [ 0, %entry ]
  ret i32 %retval.0
}

declare { i32, i1 } @llvm.sadd.with.overflow.i32(i32, i32)

