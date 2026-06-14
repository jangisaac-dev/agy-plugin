# AGY Bridge Project

## 1. 프로젝트 목적

Claude Code 안에서 Antigravity CLI `agy`를 로컬 Gemini 계열 보조 작업자로 호출한다.

이 프로젝트는 서버 제품이 아니다.  
다중 사용자 중계 서비스가 아니다.  
Google OAuth 토큰을 추출하거나 공유하지 않는다.  
공식 로컬 `agy` CLI와 사용자의 로컬 인증 또는 Google Cloud project 설정만 사용한다.

---

## 2. 기본 구조

```text
Claude Code
  → /agy:* command
  → local wrapper script
  → agy CLI 실행
  → 결과를 .ai-runs/agy/<job-id>/ 에 저장
  → Claude Code가 결과를 읽고 최종 판단
```

---

## 3. 핵심 원칙

1. 모든 작업은 사용자의 로컬 머신에서 실행한다.
2. 기본 모드는 read-only 또는 초안 생성이다.
3. 파일 수정은 명시적 승인 없이는 수행하지 않는다.
4. AGY는 속도, 초안, 테스트 생성, 문서화, 반복 작업에 집중한다.
5. 히브리어/헬라어/신학 최종 판정 모델로 사용하지 않는다.
6. stdout 캡처가 불안정할 수 있으므로 결과 파일 저장과 실패 감지를 강제한다.

---

## 4. 권장 명령 세트

```text
/agy:review
/agy:plan
/agy:fast-impl
/agy:doc
/agy:test
/agy:status
/agy:result
/agy:cancel
```

| 명령 | 목적 |
|---|---|
| `/agy:review` | 빠른 코드 리뷰 |
| `/agy:plan` | 구현 전 설계 초안 |
| `/agy:fast-impl` | 빠른 구현 초안 또는 리팩터 방향 |
| `/agy:doc` | README, 주석, 개발 문서, 변경 요약 생성 |
| `/agy:test` | 테스트 케이스 생성 |
| `/agy:status` | 실행 중인 AGY job 상태 확인 |
| `/agy:result` | 저장된 결과 회수 |
| `/agy:cancel` | 실행 중인 작업 중단 |

---

## 5. 권장 폴더 구조

```text
~/.claude/plugins/agy-bridge/
  plugin.json
  commands/
    review.md
    plan.md
    fast-impl.md
    doc.md
    test.md
    status.md
    result.md
    cancel.md
  scripts/
    agy-review.sh
    agy-plan.sh
    agy-fast-impl.sh
    agy-doc.sh
    agy-test.sh
    agy-status.sh
    agy-result.sh
    agy-cancel.sh
    agy-runner.sh
  agents/
    agy-fast-builder.md
    agy-doc-writer.md
  skills/
    agy-local-cli/
      SKILL.md
```

프로젝트별 실행 결과는 repo 내부에 저장한다.

```text
.ai-runs/
  agy/
    <job-id>/
      prompt.md
      context.txt
      result.md
      stdout.log
      stderr.log
      status.json
```

---

## 6. wrapper 실행 흐름

```text
1. repo root 확인
2. which agy 확인
3. agy --version 확인
4. job-id 생성
5. .ai-runs/agy/<job-id>/ 생성
6. git diff, staged diff, branch 정보, 파일 목록 수집
7. 명령 목적에 맞는 prompt.md 생성
8. agy -p "$PROMPT" 실행
9. stdout/stderr/exit code 저장
10. stdout이 비었고 exit code가 0이면 capture failure로 표시
11. Claude Code는 result.md 또는 stdout.log를 읽고 최종 판단
```

---

## 7. AGY 역할 정의

AGY/Gemini 계열은 다음 작업에 우선 사용한다.

- 빠른 구현 초안
- 테스트 케이스 생성
- README/문서화
- 코드 설명
- 반복적인 작은 변경 제안
- UI 구조 초안
- 대량 파일의 빠른 요약
- 단순 리팩터 방향 제시

AGY를 다음 작업의 최종 판정자로 사용하지 않는다.

- 히브리어/헬라어 형태소 최종 분석
- 신학적 결론 최종 확정
- 보안 민감 코드 자동 수정
- 인증/토큰/비밀키 관련 변경
- 대규모 아키텍처 결정
- 배포/삭제/결제 명령 실행

---

## 8. 기본 리뷰 프롬프트 템플릿

```text
You are AGY running as a fast local coding assistant for this repository.

Task:
Review the provided git diff and context quickly.

Focus:
- obvious bugs
- missing tests
- confusing code
- simple refactor opportunities
- documentation gaps

Rules:
- Be concise.
- Do not over-engineer.
- Do not modify files.
- Prefer practical suggestions.
- If the diff is acceptable, say so directly.

Output format:
1. Problems
2. Suggested fixes
3. Tests to add
4. Documentation notes
5. Final verdict
```

---

## 9. Fast Implementation 프롬프트 템플릿

```text
You are AGY running as a fast implementation planner.

Task:
Produce a practical implementation draft for the requested change.

Rules:
- Do not assume hidden requirements.
- Keep the solution simple.
- Prefer small isolated changes.
- Identify files likely to change.
- Do not execute destructive commands.
- Do not touch secrets or credentials.

Output:
1. Goal
2. Files to inspect
3. Files likely to change
4. Step-by-step implementation plan
5. Test plan
6. Risks
```

---

## 10. 문서화 프롬프트 템플릿

```text
You are AGY running as a documentation assistant.

Task:
Create or improve developer-facing documentation for the provided code/context.

Rules:
- Write for future maintainers.
- Avoid marketing language.
- Be concrete.
- Include commands only when verified from context.
- Mark uncertain details as uncertain.

Output:
1. Summary
2. Setup
3. Usage
4. Important files
5. Known limitations
6. Troubleshooting
```

---

## 11. stdout 캡처 실패 처리

AGY wrapper는 다음 조건을 검사한다.

```text
exit code = 0
stdout empty
stderr empty or non-critical
result.md empty
```

이 경우 성공으로 처리하지 말고 다음 status를 남긴다.

```json
{
  "status": "capture_failed",
  "reason": "agy exited successfully but produced no captured output",
  "suggested_action": "run interactively or use pseudo-TTY fallback"
}
```

---

## 12. 안전 기준

허용:

```text
내 로컬 머신
내 Claude Code
내 AGY CLI 로그인
내 Google OAuth 또는 Google Cloud project 설정
내 프로젝트
공식 CLI 호출
결과 파일 저장
```

금지:

```text
Google OAuth 토큰 추출
세션 파일 복사
다른 사용자에게 내 계정 중계
웹/API 서버로 프록시화
rate limit 우회
자동 배포/삭제/결제 명령 실행
```

---

## 13. 최종 운영 포지션

```text
Claude = 총괄 판단자
Codex = 실제 구현/수정/테스트
Grok = 반대자 리뷰/검색/멀티모달/대안 생성
AGY = 빠른 초안/테스트/문서화/반복 작업
```

AGY Bridge는 원어·신학 최종판정용이 아니라 **빠른 실행 엔진**이다.
