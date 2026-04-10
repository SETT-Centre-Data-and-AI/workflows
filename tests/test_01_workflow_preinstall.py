from pathlib import Path


def test_build_and_test_runs_preinstall_before_poetry_and_uv_installs() -> None:
    workflow = Path(".github/workflows/build-and-test.yaml").read_text(encoding="utf-8")

    poetry_hook = "- name: Run Pre-Install Script Before Poetry Install"
    poetry_install = "- name: Install Package (Poetry)"
    uv_hook = "- name: Run Pre-Install Script Before UV Install"
    uv_install = "- name: Install Package (UV)"

    assert poetry_hook in workflow
    assert poetry_install in workflow
    assert workflow.index(poetry_hook) < workflow.index(poetry_install)

    assert uv_hook in workflow
    assert uv_install in workflow
    assert workflow.index(uv_hook) < workflow.index(uv_install)


def test_publish_runs_preinstall_before_wheel_smoke_install() -> None:
    workflow = Path(".github/workflows/publish-to-pypi.yaml").read_text(
        encoding="utf-8"
    )

    hook = "- name: Run Pre-Install Script"
    install = "- name: Install Wheel & Smoke Test"

    assert hook in workflow
    assert install in workflow
    assert workflow.index(hook) < workflow.index(install)
