import os
import json
import pytest

from test_class import remoteTableClass


@pytest.mark.parametrize("todo_text, todo_expected_code, todo_expected_text", [
    ({ 'text': 'Este es el primer texto' }, 200, "Este es el primer texo")
#,
#    ({ 'text': 'Este es el segundo texto' }, 200, "Este es el segundo texto"),
#    ({}, 500, "Este esta bien")
])
def test_create(todo_text, todo_expected_code, todo_expected_text):
    var_test_create = remoteTableClass().launchEvent(os.environ["ENDPOINT_URL"], 'create', json.dumps(todo_text))
    assert var_test_create['statusCode'] == todo_expected_code

    text_return = json.loads(var_test_create['body'])
    if 'Items' in text_return:
        text_return = json.loads(text_return['Items'])
        print(f"1 {text_return}")
    if 'errorMsg' in text_return:
        print(f"n {text_return['errorMsg']}")
        text_return = text_return['errorMsg']
        print(f"2 {text_return}")
    if 'text' in text_return:
        print(f"y ")
        text_return = json.loads(text_return['text'])
        print(f"3 {text_return}")
    print(text_return)
    #assert text_return == todo_expected_text

