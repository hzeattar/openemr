# Role and Permission Matrix | مصفوفة الأدوار والصلاحيات

This matrix is the intended minimum-access model. It does not modify the current
administrator account or authentication configuration.

هذه المصفوفة هي نموذج أقل صلاحية مطلوبة، ولا تعدّل حساب الأدمن الحالي أو المصادقة.

| Role / الدور | Patients | Calendar | Clinical notes | Prescriptions | Billing | Reports | Users & ACL | System settings |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Administrator / مدير النظام | Full | Full | Full | Full | Full | Full | Full | Full |
| Clinic Manager / مدير العيادة | Read | Full | Limited | No | Full | Operational | No | Limited |
| Reception / الاستقبال | Demographics | Full | No | No | Limited | Appointments | No | No |
| Nurse / التمريض | Assigned patients | Read | Vitals & nursing forms | Read | No | Clinical limited | No | No |
| Doctor / الطبيب | Assigned/full by policy | Read/write | Full clinical | Full | Fee sheet limited | Own clinical | No | No |
| Billing / المحاسبة | Demographics limited | Read | Codes only | No | Full | Financial | No | No |
| Laboratory / المختبر | Assigned orders | Read | Results only | No | No | Lab only | No | No |
| Auditor / المراجع | Read only | Read | Read only | Read only | Read only | Audit | No | No |

## Implementation rules | قواعد التنفيذ

- One named account per staff member; never share usernames.
- Do not use the administrator account for daily clinical work.
- Assign permissions through ACL groups, not individual exceptions where possible.
- Review access every month and immediately when a staff member changes role.
- Disable departed staff accounts; do not delete historical identities.
- Separate financial access from clinical access wherever practical.
- Test each new role with a non-production patient before real use.

- حساب شخصي لكل موظف وعدم مشاركة الحسابات.
- استخدام مجموعات ACL ومنح أقل صلاحية لازمة.
- مراجعة الصلاحيات شهريًا وعند تغير وظيفة الموظف.
- تعطيل حساب الموظف المغادر بدل حذفه للحفاظ على سجل التدقيق.
- اختبار كل دور ببيانات تجريبية قبل استخدام بيانات مرضى حقيقية.
